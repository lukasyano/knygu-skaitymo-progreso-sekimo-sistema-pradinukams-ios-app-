import Resolver
import SwiftData
import SwiftUI

final class DefaultAuthenticationCoordinator: Coordinator {
    private var interactor: AuthenticationInteractor!

    weak var parent: (any Coordinator)?
    @Published var presentedView: AuthenticationCoordinatorPresentedView?
    @Published var route: AuthenticationCoordinatorRoute?

    init(shouldAutoNavigateToHome: Bool = false) {
        self.interactor = DefaultAuthenticationInteractor(
            coordinator: self,
            shouldAutoNavigateToHome: shouldAutoNavigateToHome
        )
    }

    @ViewBuilder
    func start() -> some View {
        AuthenticationView(interactor: interactor)
    }
}

// MARK: - Presentation

extension DefaultAuthenticationCoordinator {}

// MARK: - Navigation

extension DefaultAuthenticationCoordinator {
    func navigateToLogin() {
        route = .login
    }

    func navigateToRegister() {
        route = .registration
    }
}
