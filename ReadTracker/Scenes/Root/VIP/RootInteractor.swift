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
    @Injected private var bookRepository: BookRepository
    @Injected private var userRepository: UserRepository

    init(coordinator: DefaultRootCoordinator = Resolver.resolve()) {
        self.coordinator = coordinator
    }

    private var cancelBag = Set<AnyCancellable>()
}

extension DefaultRootInteractor: RootInteractor {
    func onAppear() {
        let authPublisher = userRepository.authStatePublisher
            .eraseToAnyPublisher()

        let refreshPublisher = bookRepository.refreshIfNeeded()
            .replaceError(with: ())
            .eraseToAnyPublisher()

        Publishers.CombineLatest(authPublisher, refreshPublisher)
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] in
                    if case let .failure(error) = $0 {
                        self?.coordinator?.presentError(
                            message: "Ops. Nutiko klaida, patikrink interneto ryšį bei pabandyk dar kartą. \(error) ",
                            onDismiss: {}
                        )
                    }
                },
                receiveValue: { [weak self] userId, _ in
                    guard userId != .none else {
                        self?.coordinator?.navigateToAuthentication()
                        return
                    }
                    self?.coordinator?.navigateToHome(userID: userId!)
                }
            )
            .store(in: &cancelBag)
    }

    func onDisappear() {
        cancelBag.removeAll()
    }
}
