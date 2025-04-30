import SwiftUI

struct AuthenticationCoordinatorView: View {
    @ObservedObject var coordinator: DefaultAuthenticationCoordinator

    var body: some View {
        NavigationStack {
            coordinator.start()
                .navigation(item: $coordinator.route, destination: navigationViewContent)
                .presentedView($coordinator.presentedView, content: presentedViewContent)
        }
        .navigationBarBackButtonHidden()
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
            Text("LOGIN")
        case .registration:
            RegistrationCoordinatorView(coordinator: .init(parent: coordinator))
        }
    }
}
