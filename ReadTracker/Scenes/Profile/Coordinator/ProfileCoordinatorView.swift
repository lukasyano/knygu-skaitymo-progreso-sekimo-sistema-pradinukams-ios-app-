import SwiftUI

struct ProfileCoordinatorView: View {
    @ObservedObject var coordinator: DefaultProfileCoordinator

    var body: some View {
        NavigationStack {
            coordinator.start()
                .presentedView($coordinator.presentedView, content: presentedViewContent)
                .navigation(item: $coordinator.route, destination: routeView(for:))
        }
    }
}

// MARK: - Presented View Content

extension ProfileCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: ProfileCoordinatorPresentedView) -> some View {
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

extension ProfileCoordinatorView {
    @ViewBuilder
    private func routeView(for route: ProfileCoordinatorRoute) -> some View {
        switch route {
        case let .login(email):
            LoginCoordinatorView(coordinator: .init(parent: coordinator, email: email, shouldAutoNavigateToHome: false))
        }
    }
}
