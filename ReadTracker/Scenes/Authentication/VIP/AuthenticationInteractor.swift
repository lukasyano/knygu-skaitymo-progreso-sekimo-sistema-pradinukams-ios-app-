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
    private weak var coordinator: DefaultAuthenticationCoordinator?

    init(
        coordinator: DefaultAuthenticationCoordinator,
        shouldAutoNavigateToHome: Bool
    ) {
        self.coordinator = coordinator
        if shouldAutoNavigateToHome {
            coordinator.navigateToLogin()
        }
    }
}

// MARK: - Business Logic

extension DefaultAuthenticationInteractor: AuthenticationInteractor {
    func tapReload() {
        
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
