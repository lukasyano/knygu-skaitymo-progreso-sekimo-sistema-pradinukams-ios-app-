import Combine
import PDFKit
import UIKit

protocol BookThumbnailWorker {
    func generateThumbnails(for books: [BookEntity], size: CGSize) -> AnyPublisher<[HomeModels.BooksPresentable], Never>
}

final class DefaultBookThumbnailWorker: BookThumbnailWorker {

    private static let fallbackImage = UIImage(
        systemName: "book.closed.fill"
    )!

    private let ioQueue = DispatchQueue(
        label: "pdf.thumbnail.queue",
        qos: .userInitiated
    )

    func generateThumbnails(
        for books: [BookEntity],
        size: CGSize
    ) -> AnyPublisher<[HomeModels.BooksPresentable], Never> {

        let publishers = books.map { book in
            thumbnail(for: book, size: size)
        }

        return Publishers.MergeMany(publishers)
            .collect()                  // wait for all
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Private helpers

    private func thumbnail(
        for book: BookEntity,
        size: CGSize
    ) -> AnyPublisher<HomeModels.BooksPresentable, Never> {

        guard let path = book.localFilePath else {
            return Just(makePresentable(book, image: Self.fallbackImage))
                   .eraseToAnyPublisher()
        }

        return Future<HomeModels.BooksPresentable, Never> { [weak self] promise in
            guard let self else { return }
            self.ioQueue.async {
                do {
                    let fileURL = URL(fileURLWithPath: path)
                    guard
                        let doc = PDFDocument(url: fileURL),
                        let page = doc.page(at: 0)
                    else {
                        print("!!!PDF CORRUPTED")
                        return
                    }

                    let image = page.thumbnail(of: size, for: .mediaBox)
                    promise(.success(self.makePresentable(book, image: image)))

                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func makePresentable(
        _ book: BookEntity,
        image: UIImage
    ) -> HomeModels.BooksPresentable {
        .init(id: book.id, title: book.title, image: image)
    }
}
