import Combine
import Foundation
import Resolver
import SwiftData
import SwiftUI

protocol HomeInteractor: AnyObject {
    func viewDidAppear()
    func onLogOutTap()
    func onProfileTap()
    func onBookClicked(_ bookID: String)
}

final class DefaultHomeInteractor {
    private weak var presenter: HomePresenter?
    private weak var coordinator: (any HomeCoordinator)?

    private let userRepository: UserRepository
    private let bookRepository: BookRepository
    private let thumbnailWorker: BookThumbnailWorker

    private var cancelBag = Set<AnyCancellable>()
    private var books: [BookEntity]?
    private var user: UserEntity?

    init(
        coordinator: any HomeCoordinator,
        presenter: HomePresenter?,
        userRepository: UserRepository = Resolver.resolve(),
        bookRepository: BookRepository = Resolver.resolve(),
        thumbnailWorker: BookThumbnailWorker = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
        self.userRepository = userRepository
        self.bookRepository = bookRepository
        self.thumbnailWorker = thumbnailWorker
    }
}

extension DefaultHomeInteractor: HomeInteractor {
    func viewDidAppear() {
        cancelBag.removeAll()
        observeUsserSession()
        fetchUserProgress()
    }

    private func getUserRole(userID: String) {
        userRepository.getCurrentUser()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in self?.receiveCurrentUser(user: $0) })
            .store(in: &cancelBag)
    }

    private func receiveCurrentUser(user: UserEntity?) {
        guard let user else { return }
        self.user = user
        fetchBooks(for: user.role)
    }

    private func observeUsserSession() {
        let logOutDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)

        userRepository.authStatePublisher
            .removeDuplicates()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .delay(for: logOutDelay, scheduler: DispatchQueue.main)
            .sink { [weak self] userId in
                guard let userId else {
                    self?.coordinator?.popToRoot()
                    return
                }
                self?.getUserRole(userID: userId)
            }
            .store(in: &cancelBag)
    }

    private func fetchBooks(for role: Role) {
        bookRepository.fetchBooks(for: role)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.coordinator?.presentError(message: "Knygų gavimas nepavyko.", onDismiss: {})
                    }
                },
                receiveValue: { [weak self] books in
                    self?.books = books
                    self?.presenter?.presentBooks(books)
                    self?.generateThumbnails(for: books)
                }
            )
            .store(in: &cancelBag)
    }

    private func fetchUserProgress() {
//        guard let userID = currentUserID else { return }
//        progressRepository.fetchProgress(forUser: userID)
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] progress in
//                self?.presenter?.presentProgress(progress)
//            })
//            .store(in: &cancelBag)
    }

    private func generateThumbnails(for books: [BookEntity]) {
        thumbnailWorker
            .generateThumbnails(for: books, size: .init(width: 150, height: 200))
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] thumbs in
                self?.presenter?.presentBookThumbnails(thumbs)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.presenter?.presentBookThumbnails(thumbs)
                }
            })
            .store(in: &cancelBag)
    }

    func onLogOutTap() {
        do {
            try userRepository.signOut()
        } catch {
            coordinator?.presentError(message: "Atsijungti nepavyko.", onDismiss: {})
        }
    }

    func onBookClicked(_ bookID: String) {
        guard let url = books?.first(where: { $0.id == bookID })?.fileURL else {
            coordinator?.presentError(message: "Nepavyko atidaryti knygos.", onDismiss: {})
            return
        }
        coordinator?.showBook(at: url)
    }

    func onProfileTap() {
        guard let user else { return }
        coordinator?.showProfile(with: user)
    }
}
