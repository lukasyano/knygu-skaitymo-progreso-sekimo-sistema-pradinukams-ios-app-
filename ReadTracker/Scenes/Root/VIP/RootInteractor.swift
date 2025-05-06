import Combine
import Foundation
import Resolver
import SwiftData

protocol RootInteractor: AnyObject {
    func onAppear()
    func onDisappear()
}

final class DefaultRootInteractor {
    private weak var coordinator: DefaultRootCoordinator?

    private let bookRepository: BookRepository
    private let userRepository: UserRepository

    private var cancelBag = Set<AnyCancellable>()

    init(
        coordinator: DefaultRootCoordinator = Resolver.resolve(),
        bookRepsitory: BookRepository = Resolver.resolve(),
        userRepository: UserRepository = Resolver.resolve()
    ) {
        self.coordinator = coordinator
        self.bookRepository = bookRepsitory
        self.userRepository = userRepository
        refreshBooksIfNeeded()
    }
}

// MARK: - Business Logic

extension DefaultRootInteractor: RootInteractor {
    private func refreshBooksIfNeeded() {
        bookRepository.refreshIfNeeded()
            .sink(
                receiveCompletion: { _ in },
                receiveValue: {}
            )
            .store(in: &cancelBag)
    }

    func onAppear() {
        let authPublisher = userRepository.authStatePublisher
            .removeDuplicates()
            .first()
            .eraseToAnyPublisher()

        let refreshPublisher = bookRepository.refreshIfNeeded()
            .replaceError(with: ())
            .eraseToAnyPublisher()

        Publishers.Zip(authPublisher, refreshPublisher)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak coordinator] userId, _ in
                    userId != nil
                        ? coordinator?.navigateToHome()
                        : coordinator?.navigateToAuthentication()
                }
            )
            .store(in: &cancelBag)
    }

    func onDisappear() {
        cancelBag.removeAll()
    }
}
