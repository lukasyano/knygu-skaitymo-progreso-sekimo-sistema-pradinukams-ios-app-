import Combine
import CryptoKit
import Foundation
import SwiftData

protocol BookDownloadService {
    func downloadBooks(force: Bool)
}

struct BookWithLocalURL {
    let entity: BookEntity
    let localURL: URL
}

final class DefaultBookDownloadService: BookDownloadService {
    // MARK: – Dependencies
    private let modelContext: ModelContext
    private let fileManager: FileManager = .default

    // MARK: – Persistent “Books” directory (Application Support)
    private lazy var booksDirectory: URL = {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory,
                                          in: .userDomainMask).first!
        var dir = appSupport.appendingPathComponent("Books", isDirectory: true)

        // Create once at startup.
        if !fileManager.fileExists(atPath: dir.path) {
            try? fileManager.createDirectory(
                at: dir,
                withIntermediateDirectories: true
            )
        }

        // Mark “do not back up” so the PDFs stay local but don’t inflate iCloud.
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        _ = try? dir.setResourceValues(resourceValues)

        return dir
    }()

    // MARK: – Init
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        _ = booksDirectory
    }

    // MARK: – Public
    func downloadBooks(force: Bool) {
        let entities = (try? modelContext.fetch(FetchDescriptor<BookEntity>())) ?? []

        for entity in entities {
            guard let remoteURL = URL(string: entity.pdfURL) else { continue }

            let destURL = localURL(for: remoteURL)

            // Skip when we already have a local file unless `force == true`.
            if !force, fileManager.fileExists(atPath: destURL.path) {
                if entity.localFilePath == nil { // first launch after upgrade
                    entity.localFilePath = destURL.path
                    try? modelContext.save()
                }
                continue
            }

            downloadPDF(from: remoteURL, to: destURL) { [weak self] success in
                guard let self, success else {
                    print("❌ Failed to download \(entity.title)")
                    return
                }

                DispatchQueue.main.async {
                    entity.localFilePath = destURL.path
                    do {
                        try self.modelContext.save()
                        print("✅ Saved \(entity.title) → \(destURL.lastPathComponent)")
                    } catch {
                        print("❌ SwiftData save error: \(error)")
                    }
                }
            }
        }
    }

    // MARK: – Helpers
    /// Generates a stable, collision‑free filename (SHA‑256 of the URL).
    private func localURL(for remoteURL: URL) -> URL {
        let filename = sha256(remoteURL.absoluteString) + ".pdf"
        return booksDirectory.appendingPathComponent(filename)
    }

    private func downloadPDF(
        from remoteURL: URL,
        to destinationURL: URL,
        completion: @escaping (Bool) -> Void
    ) {
        URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
            guard let tempURL, error == nil else {
                completion(false); return
            }

            do {
                // Replace any stale file atomically.
                if self.fileManager.fileExists(atPath: destinationURL.path) {
                    try self.fileManager.removeItem(at: destinationURL)
                }
                try self.fileManager.moveItem(at: tempURL, to: destinationURL)
                completion(true)
            } catch {
                print("⚠️ Move file error: \(error)")
                completion(false)
            }
        }.resume()
    }

    private func sha256(_ string: String) -> String {
        let data = Data(string.utf8)
        #if canImport(CryptoKit)
            let hash = SHA256.hash(data: data)
            return hash.compactMap { String(format: "%02x", $0) }.joined()
        #else
            return String(data.hashValue, radix: 16)
        #endif
    }
}
