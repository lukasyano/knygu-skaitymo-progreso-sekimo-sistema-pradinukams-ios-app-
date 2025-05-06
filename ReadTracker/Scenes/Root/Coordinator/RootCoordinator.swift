import FirebaseAuth
import Resolver
import SwiftData
import SwiftUI

final class DefaultRootCoordinator: Coordinator {
    weak var parent: (any Coordinator)?
    @Published var presentedView: None?
    @Published var route: RootCoordinatorRoute? = .carousel

    @ViewBuilder
    func start() -> some View {}
}

// MARK: - Presentation

extension DefaultRootCoordinator {}

// MARK: - Navigation

extension DefaultRootCoordinator {
    func navigateToAuthentication() {
        route = .authentication
    }

    func navigateToHome() {
        route = .home
    }
}
