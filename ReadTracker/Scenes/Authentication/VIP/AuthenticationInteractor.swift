import Combine
import Resolver
import SwiftData
import SwiftUI

protocol AuthenticationInteractor: AnyObject {
    func viewDidAppear()
    func tapLogin()
    func tapRegister()
    func tapReload()
}

final class DefaultAuthenticationInteractor {
    @Injected private var bookRepository: BookRepository
    private weak var coordinator: DefaultAuthenticationCoordinator?

    private var cancelBag = Set<AnyCancellable>()

    init(coordinator: DefaultAuthenticationCoordinator) {
        self.coordinator = coordinator
    }
}

// MARK: - Business Logic

extension DefaultAuthenticationInteractor: AuthenticationInteractor {
    func tapReload() {        
        bookRepository.refreshBooks()
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak coordinator] in
                    if case .failure = $0 {
                        coordinator?.showRefreshError(
                            message: "Ops. Atnaujinimas nepavyko. Patikrinkite interneto ryšį bei bandykite dar kartą.")
                    }
                },
                receiveValue: { [weak coordinator] in
                    coordinator?.showRefreshSuccess(message: "Knygų biblioteka atnaujinta sėkmingai!")
                }
            )
            .store(in: &cancelBag)
    }

    func tapLogin() {
        coordinator?.navigateToLogin()
    }

    func tapRegister() {
        coordinator?.navigateToRegister()
    }

    // MARK: - View Did Change
    func viewDidAppear() {}
}
