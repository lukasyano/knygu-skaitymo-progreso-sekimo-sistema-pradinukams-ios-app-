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
        case let .book(book, user):
            BookReaderCoordinatorView(coordinator: .init(book: book, user: user, parent: coordinator))

        case let .profile(userID):
            ProfileCoordinatorView(coordinator: .init(parent: coordinator, userID: userID))

        case let .error(error: error, dismiss: dismiss): EmptyView()
            // Toa
        }
    }
}

// MARK: - Navigation
extension HomeCoordinatorView {
    @ViewBuilder
    private func routeView(for route: HomeCoordinatorRoute) -> some View {
        switch route {
        // ReadBookView(url: url)
        default:
            EmptyView()
        }
    }
}
