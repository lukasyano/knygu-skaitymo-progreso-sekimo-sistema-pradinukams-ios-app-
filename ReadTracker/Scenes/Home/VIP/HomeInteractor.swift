import Combine
import Foundation
import Resolver
import SwiftData
import SwiftUI

protocol HomeInteractor: AnyObject {
    func viewDidAppear()
    func onLogOutTap()
    func onProfileTap()
    func onBookClicked(_ book: BookEntity)
}

final class DefaultHomeInteractor {
    private weak var presenter: HomePresenter?
    private weak var coordinator: (any HomeCoordinator)?

    @Injected private var userRepository: UserRepository
    @Injected private var bookRepository: BookRepository

    private var cancelBag = Set<AnyCancellable>()
    private var progress: [ProgressData] = []
    private var user: UserEntity?

    init(
        coordinator: any HomeCoordinator,
        presenter: HomePresenter?
    ) {
        self.coordinator = coordinator
        self.presenter = presenter
    }
}

extension DefaultHomeInteractor: HomeInteractor {
    func viewDidAppear() {
        cancelBag.removeAll()
        observeUsserSession()
    }

//    private func loadUserProgress(userID: String) {
//        userRepository.fetchUserProgress(userID: userID)
//            .receive(on: DispatchQueue.main)
//            .sink { completion in
//                if case let .failure(error) = completion {
//                    print("Firestore Error: \(error.localizedDescription)")
//                }
//            } receiveValue: { [weak self] progressData in
//                self?.progress = progressData
//                self?.presenter?.presentProgress(progressData)
//            }
//            .store(in: &cancelBag)
//    }

//    private func getUserRole(userID: String) {
//        userRepository.getCurrentUser()
//            .subscribe(on: DispatchQueue.global())
//            .receive(on: DispatchQueue.main)
//            .sink(receiveValue: { [weak self] in self?.receiveCurrentUser(user: $0) })
//            .store(in: &cancelBag)
//    }
//
//    private func receiveCurrentUser(user: UserEntity?) {
//        guard let user else { return }
//        self.user = user
//        presenter?.presentUser(user)
//        loadUserProgress(userID: user.id)
//    }

    private func observeUsserSession() {
        let logOutDelay: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(200)

        userRepository.authStatePublisher
            .removeDuplicates()
            .delay(for: logOutDelay, scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard $0 != .none else {
                    self?.coordinator?.popToRoot()
                    return
                }
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
