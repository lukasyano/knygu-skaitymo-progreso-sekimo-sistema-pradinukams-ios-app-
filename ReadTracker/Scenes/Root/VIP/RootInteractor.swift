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
            .removeDuplicates()
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
                    guard let userId else {
                        self?.coordinator?.navigateToAuthentication()
                        return
                    }
                    self?.navigateToHome()
                }
            )
            .store(in: &cancelBag)
    }

    private func navigateToHome() {
        userRepository.getCurrentUser()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak coordinator] in
                guard let user = $0 else {
                    coordinator?.presentError(message: "Nutiko klaida", onDismiss: {})
                    return
                }
                coordinator?.navigateToHome(user: user)
            })
            .store(in: &cancelBag)
    }

    func onDisappear() {
         cancelBag.removeAll()
    }
}
