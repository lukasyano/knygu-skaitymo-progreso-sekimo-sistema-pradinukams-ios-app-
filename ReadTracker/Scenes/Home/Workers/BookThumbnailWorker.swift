import Combine
import PDFKit
import UIKit

protocol BookThumbnailWorker {
    func generateThumbnails(for books: [Book], size: CGSize) -> AnyPublisher<[HomeModels.BooksPresentable], Never>
}

final class DefaultBookThumbnailWorker: BookThumbnailWorker {
    func generateThumbnails(for books: [Book], size: CGSize) -> AnyPublisher<[HomeModels.BooksPresentable], Never> {
        let fallbackImage = UIImage(systemName: "book")!

        let publishers = books.map { book -> AnyPublisher<HomeModels.BooksPresentable, Never> in
            guard let url = URL(string: book.pdfURL) else {
                print("⚠️ Invalid URL: \(book.pdfURL)")
                return Just(self.makePresentable(book: book, image: fallbackImage)).eraseToAnyPublisher()
            }

            return downloadPDFData(url)
                .map { [weak self] data in
                    if let data = data,
                       let image = self?.generatePdfThumbnail(of: size, from: data, atPage: 0) {
                        return self?.makePresentable(book: book, image: image) ?? self!.makePresentable(book: book, image: fallbackImage)
                    } else {
                        print("❌ Failed to create thumbnail for book: \(book.title)")
                        return self!.makePresentable(book: book, image: fallbackImage)
                    }
                }
                .replaceError(with: self.makePresentable(book: book, image: fallbackImage))
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .eraseToAnyPublisher()
    }

    private func makePresentable(book: Book, image: UIImage) -> HomeModels.BooksPresentable {
        return HomeModels.BooksPresentable(
            id: book.id,
            title: book.title,
            image: image
        )
    }

    private func generatePdfThumbnail(of size: CGSize, from data: Data, atPage index: Int) -> UIImage? {
        guard let doc = PDFDocument(data: data),
              let page = doc.page(at: index) else {
            return nil
        }

        return page.thumbnail(of: size, for: .mediaBox)
    }

    private func downloadPDFData(_ url: URL) -> AnyPublisher<Data?, Never> {
        URLSession.shared.dataTaskPublisher(for: url)
            .timeout(.seconds(5), scheduler: DispatchQueue.global())
            .map(\.data)
            .catch { error -> Just<Data?> in
                print("⏰ Timeout or error: \(error)")
                return Just(nil)
            }
            .eraseToAnyPublisher()
    }
}
