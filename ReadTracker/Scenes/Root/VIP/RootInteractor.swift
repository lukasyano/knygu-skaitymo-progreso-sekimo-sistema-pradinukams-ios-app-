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
    }
}

// MARK: - Business Logic

extension DefaultRootInteractor: RootInteractor {


    func onAppear() {
        let authPublisher = userRepository.authStatePublisher
            .removeDuplicates()
            .first()
            .eraseToAnyPublisher()

        let refreshPublisher = bookRepository.refreshIfNeeded()
            .replaceError(with: ())
            .eraseToAnyPublisher()

        Publishers.CombineLatest(authPublisher, refreshPublisher)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in
                print($0)
                },
                receiveValue: { [weak coordinator] userId, _ in
                    print("value")
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
