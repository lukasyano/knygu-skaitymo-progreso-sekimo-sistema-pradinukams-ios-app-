import SwiftUI

struct BookReaderCoordinatorView: View {
    @ObservedObject var coordinator: DefaultBookReaderCoordinator

    var body: some View {
        NavigationStack {
            coordinator.start()
                .presentedView($coordinator.presentedView, content: presentedViewContent)
                .navigation(item: $coordinator.route, destination: routeView(for:))
        }
    }
}

// MARK: - Presented View Content

extension BookReaderCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: BookReaderCoordinatorPresentedView) -> some View {
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

extension BookReaderCoordinatorView {
    @ViewBuilder
    private func routeView(for route: BookReaderCoordinatorRoute) -> some View {
        switch route {
        case let .login(email):
            LoginCoordinatorView(coordinator: .init(parent: coordinator, email: email, shouldAutoNavigateToHome: false))
        }
    }
}
