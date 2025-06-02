import Combine
import CryptoKit
import Foundation
import PDFKit
import Resolver
import SwiftData
import UIKit

protocol BookDownloadService {
    func downloadMissingBooks() -> AnyPublisher<Void, Error>
    func clearLocalFiles() -> AnyPublisher<Void, Error>
}

final class DefaultBookDownloadService: BookDownloadService {
    private var modelContext: ModelContext

    private let fileManager: FileManager = .default
    private let queue = DispatchQueue(label: "BookDownloadService", qos: .utility)
    let booksDirectory: URL

    init(modelContext: ModelContext = Resolver.resolve(), booksDirectory: URL? = nil) {
        self.modelContext = modelContext
        
        if let booksDirectory {
            self .booksDirectory = booksDirectory
        } else {
            self.booksDirectory = Self.createBooksDirectory()
        }
        print("📁 Books Directory: \(self.booksDirectory.path)")
    }

    func downloadMissingBooks() -> AnyPublisher<Void, Error> {
        guard let entities = try? modelContext.fetch(FetchDescriptor<BookEntity>()) else {
            return .fail(NSError.general)
        }

        return Publishers.Sequence(sequence: entities)
            .flatMap { [weak self] entity in
                self?.downloadAndUpdate(entity) ?? .empty()
            }
            .collect()
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func clearLocalFiles() -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else { return }

            do {
                let files = try FileManager.default.contentsOfDirectory(
                    at: self.booksDirectory,
                    includingPropertiesForKeys: nil
                )
                for file in files {
                    try FileManager.default.removeItem(at: file)
                }
                promise(.success(()))
            } catch {
                promise(.failure(error))
            }
        }
        .eraseToAnyPublisher()
    }
}

private extension DefaultBookDownloadService {
    func downloadAndUpdate(_ entity: BookEntity) -> AnyPublisher<Void, Error> {
        Deferred {
            Future { [weak self] promise in
                self?.queue.async {
                    do {
                        try self?.processEntity(entity)
                        promise(.success(()))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func processEntity(_ entity: BookEntity) throws {
        guard let pdfURL = URL(string: entity.pdfURL) else {
            throw URLError(.badURL)
        }

        let destURL = try downloadPDF(from: pdfURL, in: entity)
        try updateEntity(entity, with: destURL)
        generateThumbnail(for: entity, fileURL: destURL)
    }

    func downloadPDF(from url: URL, in entity: BookEntity) throws -> URL {
        let filename = Self.sha256(url.absoluteString) + ".pdf"
        let destURL = booksDirectory.appendingPathComponent(filename)

        if let existing = entity.fileURL, fileManager.fileExists(atPath: existing.path) {
            return existing
        }

        let data = try Data(contentsOf: url)
        let tempURL = booksDirectory.appendingPathComponent(UUID().uuidString + ".tmp")
        try data.write(to: tempURL)
        try fileManager.moveItem(at: tempURL, to: destURL)

        return destURL
    }

    func updateEntity(_ entity: BookEntity, with fileURL: URL) throws {
        try DispatchQueue.safeSync {
            entity.fileURL = fileURL
            try modelContext.save()
        }
    }

    func generateThumbnail(for entity: BookEntity, fileURL: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let pdfDocument = PDFDocument(url: fileURL),
                  let thumbnail = pdfDocument.page(at: 0)?
                  .thumbnail(of: CGSize(width: 200, height: 300), for: .mediaBox)
            else { return }

            let totalPages = pdfDocument.pageCount

            DispatchQueue.main.async {
                entity.thumbnailData = thumbnail.jpegData(compressionQuality: 0.8)
                entity.totalPages = totalPages
                try? self?.modelContext.save()
            }
        }
    }

    static func createBooksDirectory() -> URL {
        let fileManager = FileManager.default
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = documents.appendingPathComponent("Books", isDirectory: true)

        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }

        return dir
    }

    static func sha256(_ string: String) -> String {
        Data(string.utf8).sha256String
    }
}

extension Data {
    var sha256String: String {
        SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
    }
}

extension DispatchQueue {
    static func safeSync<T>(execute work: () throws -> T) rethrows -> T {
        Thread.isMainThread ? try work() : try main.sync(execute: work)
    }
}
