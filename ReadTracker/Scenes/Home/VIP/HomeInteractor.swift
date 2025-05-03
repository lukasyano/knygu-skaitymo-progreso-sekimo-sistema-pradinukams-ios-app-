import Combine
import Foundation
import Resolver
import SwiftData
import SwiftUI

protocol HomeInteractor: AnyObject {
    func viewDidChange(_ type: ViewDidChangeType)
    func onLogOutTap()
    func onBookClicked(_ bookID: String)
}

final class DefaultHomeInteractor {
    private weak var presenter: HomePresenter?
    private weak var coordinator: (any HomeCoordinator)?

    private var modelContext: ModelContext

    private let bookThumbnailWorker: BookThumbnailWorker
    private let authenticationService: AuthenticationService

    private var cancelBag = Set<AnyCancellable>()

    init(
        coordinator: any HomeCoordinator,
        presenter: HomePresenter?,
        modelContext: ModelContext,
        bookThumbnailWorker: BookThumbnailWorker = Resolver.resolve(),
        authenticationService: AuthenticationService = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.modelContext = modelContext
        self.bookThumbnailWorker = bookThumbnailWorker
        self.authenticationService = authenticationService
    }
}

extension DefaultHomeInteractor: HomeInteractor {
    func viewDidChange(_ type: ViewDidChangeType) {
        switch type {
        case .onAppear:
            cancelBag.removeAll()
            fetchBooks()

        case .onDisappear: break
        }
    }

    private func fetchBooks() {
        do {
            let entities = try modelContext.fetch(FetchDescriptor<BookEntity>())
            presenter?.presentBooks(entities)
            generateThumbnails(for: entities)
        } catch {
            coordinator?.presentError(message: "Nutiko klaida, pabandyk dar kartą.", onDismiss: {
                self.presenter?.presentLoading(false)
            })
        }
    }

    private func generateThumbnails(for entities: [BookEntity]) {
        bookThumbnailWorker
            .generateThumbnails(for: entities, size: CGSize(width: 150, height: 200))
            .sink { [weak self] singlePresentable in
                self?.presenter?.presentBookThumbnail(singlePresentable)
            }
            .store(in: &cancelBag)
    }

    func onLogOutTap() {
        do {
            try authenticationService.signOut()
            coordinator?.popToCoordinator(DefaultLoginCoordinator.self)
        } catch {
            coordinator?.presentError(
                message: "Atsijungimas nepavyko",
                onDismiss: { exit(0) }
            )
        }
    }

    func onBookClicked(_ bookID: String) {
        guard let entity = try? modelContext.fetch(FetchDescriptor<BookEntity>()).first(where: { $0.id == bookID }),
              let path = entity.localFilePath else {
            coordinator?.presentError(message: "Nepavyko rasti pasirinktos knygos.", onDismiss: {})
            return
        }

        coordinator?.showBook(at: URL(fileURLWithPath: path))
    }
}
