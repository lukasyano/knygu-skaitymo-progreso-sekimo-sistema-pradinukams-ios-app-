import SwiftUI

struct AuthenticationCoordinatorView: View {
    @ObservedObject var coordinator: DefaultAuthenticationCoordinator

    init(coordinator: DefaultAuthenticationCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        coordinator.start()
            .navigation(item: $coordinator.route, destination: navigationViewContent)
    }
}

// MARK: - Presented View Content

extension AuthenticationCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: AuthenticationCoordinatorPresentedView) -> some View {
        switch presentedView {
        default: EmptyView()
        }
    }
}

// MARK: - Navigation

extension AuthenticationCoordinatorView {
    @ViewBuilder
    private func navigationViewContent(_ route: AuthenticationCoordinatorRoute) -> some View {
        switch route {
        case .login:
            LoginCoordinatorView(coordinator: .init(parent: coordinator, email: .none, shouldAutoNavigateToHome: false))
        case .registration:
            RegistrationCoordinatorView(coordinator: .init(parent: coordinator))
        }
    }
}
