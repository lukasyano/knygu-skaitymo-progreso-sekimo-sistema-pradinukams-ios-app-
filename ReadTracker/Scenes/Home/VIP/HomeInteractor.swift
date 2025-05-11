import Combine
import Foundation
import Resolver
import SwiftData
import SwiftUI

protocol HomeInteractor: AnyObject {
   // func setCurrentBooks(_ books: [BookEntity])
    func viewDidAppear()
    func onLogOutTap()
    func onProfileTap()
    func onBookClicked(_ book: BookEntity) 
}

final class DefaultHomeInteractor {
    private weak var presenter: HomePresenter?
    private weak var coordinator: (any HomeCoordinator)?

    private let userRepository: UserRepository
    private let bookRepository: BookRepository
    private let thumbnailWorker: BookThumbnailWorker

    private var cancelBag = Set<AnyCancellable>()
    private var progress: [ProgressData] = []
   // private var books: [BookEntity] = []
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
//    func setCurrentBooks(_ books: [BookEntity]) {
//        self.books = books
//    }

    func viewDidAppear() {
        // cancelBag.removeAll()
        observeUsserSession()
    }

    private func loadUserProgress(userID: String) {
        userRepository.fetchUserProgress(userID: userID)
            .receive(on: DispatchQueue.main)
            .sink { completion in
                if case let .failure(error) = completion {
                    print("Firestore Error: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] progressData in
                self?.progress = progressData
                self?.presenter?.presentProgress(progressData)
            }
            .store(in: &cancelBag)
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
        presenter?.presentUser(user)
        loadUserProgress(userID: user.id)
    }

    private func observeUsserSession() {
        let logOutDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)

        userRepository.authStatePublisher
            .removeDuplicates()
            .delay(for: logOutDelay, scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] userId in
                guard let userId else {
                    self?.coordinator?.popToRoot()
                    return
                }
                self?.getUserRole(userID: userId)
            }
            .store(in: &cancelBag)
    }

    func onLogOutTap() {
        do {
            try userRepository.signOut()
        } catch {
            coordinator?.presentError(message: "Atsijungti nepavyko.", onDismiss: {})
        }
    }

    func onBookClicked(_ book: BookEntity) {
        guard let user else { return }

        coordinator?.showBook(book: book, with: user)
    }

    func onProfileTap() {
        guard let user else { return }
        coordinator?.showProfile(with: user)
    }
}
