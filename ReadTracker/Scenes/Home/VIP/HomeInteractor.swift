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
    private let userService: UserService
    private var userID: String?

    private var cancelBag = Set<AnyCancellable>()

    init(
        coordinator: any HomeCoordinator,
        presenter: HomePresenter?,
        modelContext: ModelContext,
        bookThumbnailWorker: BookThumbnailWorker = Resolver.resolve(),
        authenticationService: AuthenticationService = Resolver.resolve(),
        userService: UserService = Resolver.resolve(),
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.modelContext = modelContext
        self.bookThumbnailWorker = bookThumbnailWorker
        self.authenticationService = authenticationService
        self.userService = userService
    }
}

extension DefaultHomeInteractor: HomeInteractor {
    func viewDidChange(_ type: ViewDidChangeType) {
        switch type {
        case .onAppear:
            cancelBag.removeAll()

            fetchBooks()
            fetchUserBookProgress()

        case .onDisappear: break
        }
    }

    private func fetchBooks() {
        guard let userID = authenticationService.getUserID() else { return }
        self.userID = userID

        userService.getUserRole(userID: userID)
            .sink(
                receiveValue: { [weak self] role in
                    guard let self else { return }

                    guard let role else {
                        coordinator?.presentError(message: "Nutiko klaida, pabandyk dar kartą.", onDismiss: {})
                        return
                    }
                    let predicate = #Predicate<BookEntity> { $0.role == role.rawValue }

                    do {
                        let entities = try modelContext.fetch(FetchDescriptor<BookEntity>(predicate: predicate))
                        presenter?.presentBooks(entities)
                        generateThumbnails(for: entities)
                    } catch {
                        coordinator?.presentError(message: "Nutiko klaida, pabandyk dar kartą.", onDismiss: {
                            self.presenter?.presentLoading(false)
                        })
                    }
                }
            )
            .store(in: &cancelBag)
    }

    private func fetchUserBookProgress() {
        guard let userID = authenticationService.getUserID() else { return }

        userService.getUserRole(userID: userID)
            .sink(
                receiveValue: { [weak self] role in
                    guard let self else { return }
                    guard let role else { return }
                }
            ).store(in: &cancelBag)
    }

    private func generateThumbnails(for entities: [BookEntity]) {
        bookThumbnailWorker
            .generateThumbnails(for: entities, size: CGSize(width: 150, height: 200))
            .sink { [weak self] in self?.presenter?.presentBookThumbnails($0) }
            .store(in: &cancelBag)
    }

    func onLogOutTap() {
        coordinator?.popToRoot()
        do {
            try authenticationService.signOut()
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
