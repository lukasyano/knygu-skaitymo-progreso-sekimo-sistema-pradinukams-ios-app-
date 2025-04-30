import SwiftUI

struct LoginCoordinatorView: View {
    @ObservedObject var coordinator: DefaultLoginCoordinator

    var body: some View {
        NavigationStack {
            coordinator.start()
                .blur(radius: coordinator.presentedView != nil ? 5 : 0, opaque: false)
                .presentedView($coordinator.presentedView, content: presentedViewContent)
                .navigation(item: $coordinator.route, destination: routeView(for:))
        }
    }
}

// MARK: - Presented View Content

extension LoginCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: LoginCoordinatorPresentedView) -> some View {
        switch presentedView {
        case let .validationError(error):
            ToastMessage(
                message: error,
                dismiss: { coordinator.presentedView = .none },
                toastState: .error
            )
            .clearModalBackground()

        case let .infoMessage(message):
            ToastMessage(
                message: message,
                delay: 10,
                dismiss: {
                    coordinator.presentedView = .none
                    coordinator.navigateToMain()
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
        case .main:
            Text("MainView")
        }
    }
}
