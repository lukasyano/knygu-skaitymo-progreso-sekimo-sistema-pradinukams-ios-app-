import SwiftUI

struct AuthenticationCoordinatorView: View {
    @ObservedObject var coordinator: DefaultAuthenticationCoordinator

    init(coordinator: DefaultAuthenticationCoordinator) {
        self.coordinator = coordinator
    }

    var body: some View {
        coordinator.start()
            .navigation(item: $coordinator.route, destination: navigationViewContent)
            .presentedView($coordinator.presentedView, content: presentedViewContent)
    }
}

extension AuthenticationCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: AuthenticationCoordinatorPresentedView) -> some View {
        switch presentedView {
        case let .failure(message):
            ToastMessage(
                message: message,
                delay: 4,
                dismiss: coordinator.dismissPresented,
                toastState: .error
            )
            .clearModalBackground()

        case let .info(message):
            ToastMessage(
                message: message,
                delay: 2,
                dismiss: coordinator.dismissPresented,
                toastState: .info
            )
            .clearModalBackground()
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
