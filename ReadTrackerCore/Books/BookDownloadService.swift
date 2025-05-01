import Combine
import Foundation

struct BookWithLocalURL {
    let book: Book
    let localURL: URL
}

protocol BookDownloadService {
    func downloadBooks(_ books: [Book]) -> AnyPublisher<[BookWithLocalURL], Never>
}

final class DefaultBookDownloadService: BookDownloadService {
    func downloadBooks(_ books: [Book]) -> AnyPublisher<[BookWithLocalURL], Never> {
        let publishers = books.compactMap { book -> AnyPublisher<BookWithLocalURL?, Never>? in
            guard let url = URL(string: book.pdfURL) else { return nil }

            return downloadPDF(from: url)
                .map { localURL in
                    guard let localURL else { return nil }
                    return BookWithLocalURL(book: book, localURL: localURL)
                }
                .replaceError(with: nil)
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { $0.compactMap { $0 } }
            .eraseToAnyPublisher()
    }

    private func downloadPDF(from remoteURL: URL) -> AnyPublisher<URL?, Error> {
        Future { promise in
            do {
                let fileManager = FileManager.default
                let cachesDirectory = fileManager
                    .urls(for: .cachesDirectory, in: .userDomainMask)
                    .first!
                let booksDirectory = cachesDirectory.appendingPathComponent("Books", isDirectory: true)

                try fileManager.createDirectory(at: booksDirectory, withIntermediateDirectories: true)

                let destinationURL = booksDirectory.appendingPathComponent(remoteURL.lastPathComponent)

                if fileManager.fileExists(atPath: destinationURL.path) {
                    promise(.success(destinationURL))
                    return
                }

                URLSession.shared.downloadTask(with: remoteURL) { tempURL, _, error in
                    guard let tempURL, error == nil else {
                        promise(.success(nil))
                        return
                    }

                    do {
                        try? fileManager.removeItem(at: destinationURL)
                        try fileManager.moveItem(at: tempURL, to: destinationURL)
                        promise(.success(destinationURL))
                    } catch {
                        promise(.success(nil))
                    }

                }.resume()

            } catch {
                promise(.success(nil))
            }
        }
        .eraseToAnyPublisher()
    }
}
