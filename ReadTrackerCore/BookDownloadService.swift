import Combine
import Foundation
import Resolver
import SwiftData
import SwiftUI

struct BookWithLocalURL {
    let book: Book
    let localURL: URL
}

protocol BookDownloadService {
    func downloadBooksIfNeeded(_ books: [BookEntity])
}

final class DefaultBookDownloadService: BookDownloadService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func downloadBooksIfNeeded(_ books: [BookEntity]) {
        let booksToDownload = books.filter { $0.localFilePath == nil }

        for book in booksToDownload {
            guard let remoteURL = URL(string: book.pdfURL) else { continue }

            downloadPDF(from: remoteURL) { localURL in
                guard let localURL else {
                    print("Failed to download \(book.title)")
                    return
                }

                DispatchQueue.main.async {
                    book.localFilePath = localURL.path
                    do {
                        try self.modelContext.save()
                        print("✅ Downloaded and saved: \(book.title)")
                    } catch {
                        print("❌ Failed to update SwiftData for \(book.title): \(error)")
                    }
                }
            }
        }
    }

    private func downloadPDF(from url: URL, completion: @escaping (URL?) -> Void) {
        let fileManager = FileManager.default
        let dir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let booksDir = dir.appendingPathComponent("Books", isDirectory: true)

        try? fileManager.createDirectory(at: booksDir, withIntermediateDirectories: true)

        let destinationURL = booksDir.appendingPathComponent(url.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            completion(destinationURL)
            return
        }

        URLSession.shared.downloadTask(with: url) { tempURL, _, error in
            guard let tempURL, error == nil else {
                completion(nil)
                return
            }

            do {
                try? fileManager.removeItem(at: destinationURL)
                try fileManager.moveItem(at: tempURL, to: destinationURL)
                completion(destinationURL)
            } catch {
                completion(nil)
            }
        }
        .resume()
    }
}
