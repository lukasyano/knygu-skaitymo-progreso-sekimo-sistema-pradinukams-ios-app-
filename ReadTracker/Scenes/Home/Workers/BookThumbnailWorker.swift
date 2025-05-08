import Combine
import PDFKit
import UIKit

protocol BookThumbnailWorker {
    func generateThumbnails(for books: [BookEntity], size: CGSize) -> AnyPublisher<[HomeModels.BooksPresentable], Never>
}

final class DefaultBookThumbnailWorker: BookThumbnailWorker {
    private static let fallbackImage = UIImage(systemName: "book.closed.fill") ?? .init()
    private let ioQueue = DispatchQueue(
        label: "pdf.thumbnail.queue",
        qos: .userInitiated,
        attributes: .concurrent // Concurrent processing
    )

    func generateThumbnails(
        for books: [BookEntity],
        size: CGSize
    ) -> AnyPublisher<[HomeModels.BooksPresentable], Never> {
        Publishers.Sequence(sequence: books)
            .flatMap(maxPublishers: .max(4)) { book in
                self.thumbnail(for: book, size: size)
            }
            .collect()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Private helpers

    private func thumbnail(
        for book: BookEntity,
        size: CGSize
    ) -> AnyPublisher<HomeModels.BooksPresentable, Never> {
        Future<HomeModels.BooksPresentable, Never> { promise in
            self.ioQueue.async {
                guard let fileURL = book.fileURL else {
                    let fallback = self.makePresentable(book, totalPages: nil, image: Self.fallbackImage)
                    return promise(.success(fallback))
                }
                
                // Offload PDF processing to global queue
                DispatchQueue.global().async {
                    guard
                        let doc = PDFDocument(url: fileURL),
                        let page = doc.page(at: 0)
                    else {
                        let fallback = self.makePresentable(book, totalPages: nil, image: Self.fallbackImage)
                        return promise(.success(fallback))
                    }
                    
                    let image = page.thumbnail(of: size, for: .mediaBox)
                    let totalPages = doc.pageCount
                    let presentable = self.makePresentable(book, totalPages: totalPages, image: image)
                    promise(.success(presentable))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func makePresentable(
        _ book: BookEntity,
        totalPages: Int?,
        image: UIImage
    ) -> HomeModels.BooksPresentable {
        .init(id: book.id, title: book.title, readedPages: nil, totalPages: totalPages, image: image)
    }
}
