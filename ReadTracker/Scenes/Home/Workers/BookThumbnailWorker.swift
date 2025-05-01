import Combine
import PDFKit
import UIKit

protocol BookThumbnailWorker {
    func generateThumbnails(for books: [Book], size: CGSize) -> AnyPublisher<[HomeModels.BooksPresentable], Never>
}

final class DefaultBookThumbnailWorker: BookThumbnailWorker {
    func generateThumbnails(for books: [Book], size: CGSize) -> AnyPublisher<[HomeModels.BooksPresentable], Never> {
        let publishers = books.compactMap { book -> AnyPublisher<HomeModels.BooksPresentable?, Never>? in
            guard let url = URL(string: book.pdfURL) else { return nil }
            let fallbackImage: UIImage = .init(systemName: "book")!
            
            return downloadPDFData(url)
                .map { [weak self] data in
                    guard let data else { return nil }

                    return HomeModels.BooksPresentable(
                        id: book.id,
                        title: book.title,
                        image: self?.generatePdfThumbnail(of: size, from: data, atPage: 0) ?? fallbackImage
                    )
                }
                .eraseToAnyPublisher()
        }

        return Publishers.MergeMany(publishers)
            .collect()
            .map { $0.compactMap { $0 } }
            .eraseToAnyPublisher()
    }

    private func generatePdfThumbnail(of size: CGSize, from data: Data, atPage index: Int) -> UIImage? {
        guard let doc = PDFDocument(data: data),
              let page = doc.page(at: index) else { return nil }

        return page.thumbnail(of: size, for: .mediaBox)
    }

    private func downloadPDFData(_ url: URL) -> AnyPublisher<Data?, Never> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .map(Optional.init)
            .catch { _ in Just(nil) }
            .eraseToAnyPublisher()
    }
}
