import Combine
import Foundation
import Resolver
import SwiftData
import SwiftUI

protocol BookDownloadService {
    /// Downloads all book files, optionally clearing entity paths but preserving files.
    func downloadBooks(force: Bool)
}

/// Holds a BookEntity and its local file URL after download.
struct BookWithLocalURL {
    let entity: BookEntity
    let localURL: URL
}

final class DefaultBookDownloadService: BookDownloadService {
    private let modelContext: ModelContext
    private let fileManager: FileManager = .default
    private let cacheDirectoryName = "Books"

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func downloadBooks(force: Bool) {
        if force {
            resetLocalPaths()
        }

        let booksToDownload = (try? modelContext.fetch(FetchDescriptor<BookEntity>())) ?? []
        for entity in booksToDownload {
            guard entity.localFilePath == nil,
                  let remoteURL = URL(string: entity.pdfURL)
            else { continue }

            downloadPDF(from: remoteURL) { [weak self] localURL in
                guard let self = self, let localURL = localURL else {
                    print("❌ Failed to download: \(entity.title)")
                    return
                }
                DispatchQueue.main.async {
                    entity.localFilePath = localURL.path
                    do {
                        try self.modelContext.save()
                        print("✅ Downloaded and saved: \(entity.title)")
                    } catch {
                        print("❌ SwiftData update error for \(entity.title): \(error)")
                    }
                }
            }
        }
    }

    /// Clears only the localFilePath on all entities, preserving cached files.
    private func resetLocalPaths() {
        do {
            let allEntities = try modelContext.fetch(FetchDescriptor<BookEntity>())
            for entity in allEntities {
                entity.localFilePath = nil
            }
            try modelContext.save()
            print("🔄 Reset localFilePath on all entities.")
        } catch {
            print("⚠️ Error resetting entities: \(error)")
        }
    }

    /// Downloads PDF to a caches directory, returns local URL on success.
    private func downloadPDF(from url: URL, completion: @escaping (URL?) -> Void) {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let booksDir = cachesDir.appendingPathComponent(cacheDirectoryName, isDirectory: true)

        do {
            try fileManager.createDirectory(at: booksDir, withIntermediateDirectories: true)
        } catch {
            print("⚠️ Could not create books cache dir: \(error)")
        }

        let destinationURL = booksDir.appendingPathComponent(url.lastPathComponent)
        if fileManager.fileExists(atPath: destinationURL.path) {
            completion(destinationURL)
            return
        }

        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL = tempURL, error == nil else {
                completion(nil)
                return
            }
            do {
                try self.fileManager.moveItem(at: tempURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                print("⚠️ Error moving downloaded file: \(error)")
                completion(nil)
            }
        }.resume()
    }
}
