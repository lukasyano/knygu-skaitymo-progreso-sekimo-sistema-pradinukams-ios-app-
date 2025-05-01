import SwiftUI

struct HomeCoordinatorView: View {
    @ObservedObject var coordinator: DefaultHomeCoordinator

    var body: some View {
        coordinator.start()
            .navigation(item: $coordinator.route, destination: routeView(for:))
            .presentedView($coordinator.presentedView, content: presentedViewContent)
            .navigationBarBackButtonHidden()
    }
}

// MARK: - Presented View Content
extension HomeCoordinatorView {
    @ViewBuilder
    private func presentedViewContent(_ presentedView: HomeCoordinatorPresentedView) -> some View {
        switch presentedView {
        default: EmptyView()
        }
    }
}

// MARK: - Navigation
extension HomeCoordinatorView {
    @ViewBuilder
    private func routeView(for route: HomeCoordinatorRoute) -> some View {
        switch route {
        default: EmptyView()
        }
    }
}
