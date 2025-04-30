import SwiftUI

struct RegistrationCoordinatorView: View {
    @ObservedObject var coordinator: DefaultRegistrationCoordinator

    var body: some View {
        NavigationStack {
            coordinator.start()
                .presentedView($coordinator.presentedView, content: presentedViewContent)
                .navigation(item: $coordinator.route, destination: routeView(for:))
        }
    }
}

// MARK: - Presented View Content

extension RegistrationCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: RegistrationCoordinatorPresentedView) -> some View {
        switch presentedView {
        case let .validationError(error):
            ErrorToast(
                message: error,
                dismiss: { coordinator.presentedView = .none }
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
        default: EmptyView()
        }
    }
}
