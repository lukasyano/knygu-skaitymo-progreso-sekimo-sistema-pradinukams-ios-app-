import Combine
import Foundation
import Resolver

protocol HomeInteractor: AnyObject {
    func viewDidChange(_ type: ViewDidChangeType)
    func onLogOutTap()
}

final class DefaultHomeInteractor {
    // MARK: - VIP
    private weak var presenter: HomePresenter?
    private weak var coordinator: (any HomeCoordinator)?

    // MARK: - Dependencies
    private let bookRepository: BookRepository
    private let bookThumbnailWorker: BookThumbnailWorker
    private let bookDownloadService: BookDownloadService
    private let authenticationService: AuthenticationService

    // MARK: - Properties
    private lazy var cancelBag = Set<AnyCancellable>()
    private var books: [Book]?

    // MARK: - Init
    init(
        coordinator: any HomeCoordinator,
        presenter: HomePresenter?,
        bookRepository: BookRepository = Resolver.resolve(),
        bookThumbnailWorker: BookThumbnailWorker = Resolver.resolve(),
        bookDownloadService: BookDownloadService = Resolver.resolve(),
        authenticationService: AuthenticationService = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.bookRepository = bookRepository
        self.bookThumbnailWorker = bookThumbnailWorker
        self.bookDownloadService = bookDownloadService
        self.authenticationService = authenticationService
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
            cancelBag.removeAll()
            presenter?.presentLoading(false)
        }
    }

    private func fetchBooks() {
        bookRepository.fetchBooks()
           // .receive(on: DispatchQueue.main)
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
            .generateThumbnails(for: books, size: CGSize(width: 150, height: 200))
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        print("Failed to generate thumbnails:", error)
                    }
                },
                receiveValue: { [weak self] in self?.receiveThumbnails($0) }
            )
            .store(in: &cancelBag)
    }

    private func receiveThumbnails(_ books: [HomeModels.BooksPresentable]) {
        print("Received thumbnails : \(books.count)")
        presenter?.presentBooks(books)
    }

    private func downloadBooksToDisk(_ books: [Book]) {
        bookDownloadService.downloadBooks(books)
            .sink { downloaded in
                print("✅ PDF failai atsiųsti: \(downloaded.count)")
            }
            .store(in: &cancelBag)
    }

    func onLogOutTap() {
        do {
            try authenticationService.signOut()
            coordinator?.popToRoot()
        } catch {
            coordinator?.presentError(
                message: "Atsijungimas nepavyko",
                onDismiss: { exit(0) }
            )
        }
    }

    func tapConfirm() {}
}
