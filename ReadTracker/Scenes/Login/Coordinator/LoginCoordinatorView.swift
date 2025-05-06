import SwiftUI

struct LoginCoordinatorView: View {
    @ObservedObject var coordinator: DefaultLoginCoordinator

    var body: some View {
        coordinator.start()
            .presentedView($coordinator.presentedView, content: presentedViewContent)
            .navigation(item: $coordinator.route, destination: routeView(for:))
    }
}

// MARK: - Presented View Content

extension LoginCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: LoginCoordinatorPresentedView) -> some View {
        switch presentedView {
        case let .validationError(error, onClose):
            ToastMessage(
                message: error,
                dismiss: {
                    coordinator.dismissPresented()
                    onClose()
                },
                toastState: .error
            )
            .clearModalBackground()

        case let .infoMessage(message, onClose):
            ToastMessage(
                message: message,
                delay: 10,
                dismiss: {
                    onClose()
                    coordinator.presentedView = nil
                },
                toastState: .info
            )
            .clearModalBackground()
        }
    }
}

// MARK: - Navigation

extension LoginCoordinatorView {
    @ViewBuilder
    private func routeView(for route: LoginCoordinatorRoute) -> some View {
        switch route {
        case .home:
            HomeCoordinatorView(coordinator: .init(parent: coordinator))
        }
    }
}
