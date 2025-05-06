import Combine
import CryptoKit
import Foundation
import Resolver
import SwiftData

struct BookWithLocalURL {
    let entity: BookEntity
    let localURL: URL
}

protocol BookDownloadService {
    var booksDirectory: URL { get }
    func downloadMissingBooks() -> AnyPublisher<[BookWithLocalURL], Error>
}

final class DefaultBookDownloadService: BookDownloadService {
    let booksDirectory: URL
    private let modelContext: ModelContext
    private let fileManager: FileManager
    private let queue = DispatchQueue(label: "BookDownloadService", qos: .utility)

    init(
        modelContext: ModelContext = Resolver.resolve(),
        fileManager: FileManager = .default
    ) {
        self.modelContext = modelContext
        self.fileManager = fileManager

        // Set up books directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        var dir = appSupport.appendingPathComponent("Books", isDirectory: true)

        // Create directory if needed
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        // Exclude from backups
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)

        self.booksDirectory = dir
    }

    func downloadMissingBooks() -> AnyPublisher<[BookWithLocalURL], Error> {
        let entities = (try? modelContext.fetch(FetchDescriptor<BookEntity>())) ?? []
        return Publishers.MergeMany(entities.map(downloadIfNeeded))
            .collect()
            .eraseToAnyPublisher()
    }

    private func downloadIfNeeded(for entity: BookEntity) -> AnyPublisher<BookWithLocalURL, Error> {
        Future<AnyPublisher<BookWithLocalURL, Error>, Never> { [weak self] promise in
            guard let self else {
                return promise(.success(Empty().eraseToAnyPublisher()))
            }

            self.queue.async {
                guard let pdfURL = URL(string: entity.pdfURL) else {
                    return promise(.success(Fail(error: URLError(.badURL)).eraseToAnyPublisher()))
                }

                let filename = self.sha256(pdfURL.absoluteString) + ".pdf"
                let destURL = self.booksDirectory.appendingPathComponent(filename)

                if self.fileManager.fileExists(atPath: destURL.path) {
                    promise(.success(self.updateEntityIfNeeded(entity: entity, destURL: destURL)))
                    return
                }

                if let existingURL = entity.fileURL, self.fileManager.fileExists(atPath: existingURL.path) {
                    promise(.success(Just(BookWithLocalURL(entity: entity, localURL: existingURL))
                            .setFailureType(to: Error.self)
                            .eraseToAnyPublisher()))
                    return
                }

                let publisher = URLSession.shared.dataTaskPublisher(for: pdfURL)
                    .tryMap { data, response -> Data in
                        guard let httpResponse = response as? HTTPURLResponse,
                              200 ... 299 ~= httpResponse.statusCode else {
                            throw URLError(.badServerResponse)
                        }
                        return data
                    }
                    .tryMap { [weak self] data -> BookWithLocalURL in
                        guard let self else { throw URLError(.cancelled) }
                        let tempURL = self.booksDirectory
                            .appendingPathComponent(UUID().uuidString)
                            .appendingPathExtension("tmp")
                        try data.write(to: tempURL, options: .atomic)
                        try self.fileManager.moveItem(at: tempURL, to: destURL)
                        return try self.updateEntity(entity: entity, destURL: destURL)
                    }
                    .eraseToAnyPublisher()

                promise(.success(publisher))
            }
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }

    private func updateEntityIfNeeded(entity: BookEntity, destURL: URL) -> AnyPublisher<BookWithLocalURL, Error> {
        Future { [weak self] promise in
            DispatchQueue.main.async {
                guard let self else { return promise(.failure(URLError(.cancelled))) }

                do {
                    if entity.fileURL != destURL {
                        entity.fileURL = destURL
                        try self.modelContext.save()
                    }
                    promise(.success(BookWithLocalURL(entity: entity, localURL: destURL)))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func updateEntity(entity: BookEntity, destURL: URL) throws -> BookWithLocalURL {
        try DispatchQueue.main.sync {
            entity.fileURL = destURL
            try modelContext.save()
            return BookWithLocalURL(entity: entity, localURL: destURL)
        }
    }

    private func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
