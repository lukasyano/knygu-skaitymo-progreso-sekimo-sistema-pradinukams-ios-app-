import FirebaseAuth
import Resolver
import SwiftData
import SwiftUI

final class DefaultRootCoordinator: Coordinator {
    weak var parent: (any Coordinator)?
    @Published var presentedView: RootCoordinatorPresentedView?
    @Published var route: RootCoordinatorRoute? = .carousel

    @ViewBuilder
    func start() -> some View {}
}

extension DefaultRootCoordinator {
    func navigateToAuthentication() {
        route = .authentication
    }

    func navigateToHome(userID: String) {
        route = .home(userID: userID)
    }

    func presentError(
        message: String,
        onDismiss: @escaping () -> Void
    ) {
        presentedView = .error(error: message, dismiss: onDismiss)
    }
}
