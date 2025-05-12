import Resolver
import SwiftData
import SwiftUI

protocol AuthenticationCoordinator: Coordinator {
    func navigateToLogin()
    func navigateToRegister()
    func showRefreshError(message: String)
    func showRefreshSuccess(message: String)
}

final class DefaultAuthenticationCoordinator: AuthenticationCoordinator {
    private var interactor: AuthenticationInteractor!

    weak var parent: (any Coordinator)?
    @Published var presentedView: AuthenticationCoordinatorPresentedView?
    @Published var route: AuthenticationCoordinatorRoute?

    init() {
        self.interactor = DefaultAuthenticationInteractor(
            coordinator: self,
        )
    }

    @ViewBuilder
    func start() -> some View {
        AuthenticationView(interactor: interactor)
    }
}

extension DefaultAuthenticationCoordinator {
    func navigateToLogin() {
        route = .login
    }

    func navigateToRegister() {
        route = .registration
    }

    func showRefreshError(message: String) {
        presentedView = .failure(message)
    }

    func showRefreshSuccess(message: String) {
        presentedView = .info(message)
    }
}
