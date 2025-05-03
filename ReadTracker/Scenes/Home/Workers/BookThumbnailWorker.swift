import Combine
import PDFKit
import UIKit

protocol BookThumbnailWorker {
    func generateThumbnails(for books: [BookEntity], size: CGSize) -> AnyPublisher<HomeModels.BooksPresentable, Never>
}

final class DefaultBookThumbnailWorker: BookThumbnailWorker {
    func generateThumbnails(for books: [BookEntity], size: CGSize) -> AnyPublisher<HomeModels.BooksPresentable, Never> {
        let fallbackImage = UIImage(systemName: "book")!

        let publishers = books.map { book -> AnyPublisher<HomeModels.BooksPresentable, Never> in
            guard let path = book.localFilePath else {
                return Just(makePresentable(book: book, image: fallbackImage))
                    .eraseToAnyPublisher()
            }

            return Future<HomeModels.BooksPresentable, Never> { promise in
                DispatchQueue.global(qos: .userInitiated).async {
                    let fileURL = URL(fileURLWithPath: path)
                    let presentable: HomeModels.BooksPresentable

                    if let data = try? Data(contentsOf: fileURL),
                       let image = self.generatePdfThumbnail(of: size, from: data, atPage: 0) {
                        presentable = self.makePresentable(book: book, image: image)
                    } else {
                        print("❌ Failed to generate thumbnail for \(book.title)")
                        presentable = self.makePresentable(book: book, image: fallbackImage)
                    }

                    promise(.success(presentable))
                }
            }
            .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .receive(on: DispatchQueue.main) // emit updates on main thread
            .eraseToAnyPublisher()
    }

    private func makePresentable(book: BookEntity, image: UIImage) -> HomeModels.BooksPresentable {
        HomeModels.BooksPresentable(
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
}
