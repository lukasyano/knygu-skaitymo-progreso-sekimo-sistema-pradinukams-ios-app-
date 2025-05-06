import SwiftUI

struct RegistrationCoordinatorView: View {
    @ObservedObject var coordinator: DefaultRegistrationCoordinator

    var body: some View {
        coordinator.start()
            .presentedView($coordinator.presentedView, content: presentedViewContent)
            .navigation(item: $coordinator.route, destination: routeView(for:))
    }
}

// MARK: - Presented View Content

extension RegistrationCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: RegistrationCoordinatorPresentedView) -> some View {
        switch presentedView {
        case let .validationError(error, onDismiss):
            ToastMessage(
                message: error,
                dismiss: {
                    coordinator.dismissPresented()
                    onDismiss()
                },
                toastState: .error
            )
            .clearModalBackground()

        case let .infoMessage(message, onDismiss):
            ToastMessage(
                message: message,
                delay: 10,
                dismiss: {
                    coordinator.dismissPresented()
                    onDismiss()
                },
                toastState: .info
            )
            .clearModalBackground()
        }
    }
}

// MARK: - Navigation

extension RegistrationCoordinatorView {
    @ViewBuilder
    private func routeView(for route: RegistrationCoordinatorRoute) -> some View {
        switch route {
        case let .login(email):
            LoginCoordinatorView(coordinator: .init(parent: coordinator, email: email, shouldAutoNavigateToHome: false))
        }
    }
}
