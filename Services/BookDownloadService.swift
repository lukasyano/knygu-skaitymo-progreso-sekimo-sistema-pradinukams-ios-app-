import Combine
import CryptoKit
import Foundation
import SwiftData
import Resolver

protocol BookDownloadService {
    /// Downloads all book PDFs, optionally forcing re-download.
    /// Emits an array of BookWithLocalURL when complete.
    func downloadBooks() -> AnyPublisher<[BookWithLocalURL], Error>
}

struct BookWithLocalURL {
    let entity: BookEntity
    let localURL: URL
}

final class DefaultBookDownloadService: BookDownloadService {
    private let modelContext: ModelContext
    private let fileManager: FileManager
    private let booksDirectory: URL

    init(
        modelContext: ModelContext = Resolver.resolve(),
        fileManager: FileManager = .default
    ) {
        self.modelContext = modelContext
        self.fileManager = fileManager

        // Prepare application-support directory for stored PDFs
        let appSupport = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        var dir = appSupport.appendingPathComponent("Books", isDirectory: true)
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? dir.setResourceValues(values)
        self.booksDirectory = dir
    }

    func downloadBooks() -> AnyPublisher<[BookWithLocalURL], Error> {
        // Fetch all BookEntity records
        let entities = (try? modelContext.fetch(FetchDescriptor<BookEntity>())) ?? []

        // Create a publisher per entity
        let publishers = entities.map { entity -> AnyPublisher<BookWithLocalURL, Error> in
            guard let remoteURL = URL(string: entity.pdfURL) else {
                return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
            }
            let filename = sha256(remoteURL.absoluteString) + ".pdf"
            let destURL = booksDirectory.appendingPathComponent(filename)

            // If not forcing, and file exists, just return it
            if fileManager.fileExists(atPath: destURL.path) {
                if entity.fileURL == nil {
                    entity.fileURL = destURL
                    try? modelContext.save()
                }
                return .just(.init(entity: entity, localURL: destURL))
            }

            // Otherwise download afresh
            return URLSession.shared.dataTaskPublisher(for: remoteURL)
                .map(\.data)
                .tryMap { [weak self] data -> BookWithLocalURL in
                    guard let self else { throw URLError(.cancelled) }
                    // Write data to file
                    if fileManager.fileExists(atPath: destURL.path) {
                        try fileManager.removeItem(at: destURL)
                    }
                    try data.write(to: destURL, options: .atomic)
                    entity.fileURL = destURL
                    try modelContext.save()
                    return BookWithLocalURL(entity: entity, localURL: destURL)
                }
                .eraseToAnyPublisher()
        }

        // Merge all individual downloads and collect into an array
        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }

    // Helper: SHA-256 hash for deterministic filenames
    private func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
