import Combine
import Foundation
import Resolver

protocol HomeInteractor: AnyObject {
    func viewDidChange(_ type: ViewDidChangeType)
    func tapConfirm()
}

final class DefaultHomeInteractor {
    // MARK: - VIP
    private weak var presenter: HomePresenter?
    private weak var coordinator: (any HomeCoordinator)?

    // MARK: - Dependencies
    private let bookRepository: BookRepository
    private let bookThumbnailWorker: BookThumbnailWorker
    private let bookDownloadService: BookDownloadService

    // MARK: - Properties
    private lazy var cancelBag = Set<AnyCancellable>()
    private var books: [Book]? // saugoma jei reikia naudoti vėliau

    // MARK: - Init
    init(
        coordinator: any HomeCoordinator,
        presenter: HomePresenter,
        bookRepository: BookRepository = Resolver.resolve(),
        bookThumbnailWorker: BookThumbnailWorker = Resolver.resolve(),
        bookDownloadService: BookDownloadService = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.bookRepository = bookRepository
        self.bookThumbnailWorker = bookThumbnailWorker
        self.bookDownloadService = bookDownloadService
    }
}

// MARK: - Business Logic
extension DefaultHomeInteractor: HomeInteractor {
    func viewDidChange(_ type: ViewDidChangeType) {
        switch type {
        case .onAppear:
            cancelBag.removeAll()
            fetchBooks()

        case .onDisappear:
            presenter?.presentLoading(false)
        }
    }

    private func fetchBooks() {
        bookRepository.fetchBooks()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] books in
                    guard let self else { return }
                    self.books = books

                    generateThumbnails(for: books)

                    downloadBooksToDisk(books)
                }
            )
            .store(in: &cancelBag)
    }

    private func generateThumbnails(for books: [Book]) {
        bookThumbnailWorker
            .generateThumbnails(for: books, size: CGSize(width: 100, height: 100))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] books in
                self?.presenter?.presentBooks(books)
            }
            .store(in: &cancelBag)
    }

    private func downloadBooksToDisk(_ books: [Book]) {
        bookDownloadService.downloadBooks(books)
            .sink { downloaded in
                print("✅ PDF failai atsiųsti: \(downloaded.count)")
            }
            .store(in: &cancelBag)
    }

    func tapConfirm() {
        // Vieta veiksmui, kai paspaudžiama „patvirtinti“
    }
}
