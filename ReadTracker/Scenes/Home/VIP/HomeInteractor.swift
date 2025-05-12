import Combine
import Foundation
import Resolver
import SwiftData
import SwiftUI

protocol HomeInteractor: AnyObject {
    func viewDidAppear()
    func onLogOutTap()
    func onProfileTap()
    func onBookClicked(_ book: BookEntity, with user: UserEntity)
}

final class DefaultHomeInteractor {
    private weak var presenter: HomePresenter?
    private weak var coordinator: (any HomeCoordinator)?

    @Injected private var userRepository: UserRepository
    @Injected private var bookRepository: BookRepository

    private var cancelBag = Set<AnyCancellable>()
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

    func onBookClicked(_ book: BookEntity, with user: UserEntity) {
        coordinator?.showBook(book: book, with: user)
    }

    func onProfileTap() {
        coordinator?.showProfile()
    }
}
