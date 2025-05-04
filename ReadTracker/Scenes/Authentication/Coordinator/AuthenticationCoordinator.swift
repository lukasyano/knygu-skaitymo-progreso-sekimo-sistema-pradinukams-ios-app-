import Resolver
import SwiftData
import SwiftUI

final class DefaultAuthenticationCoordinator: Coordinator {
    private var interactor: AuthenticationInteractor!

    private let modelContext: ModelContext
    weak var parent: (any Coordinator)?
    @Published var presentedView: AuthenticationCoordinatorPresentedView?
    @Published var route: AuthenticationCoordinatorRoute?

    init(modelContext: ModelContext, shouldAutoNavigateToHome: Bool = false) {
        self.modelContext = modelContext
        self.interactor = DefaultAuthenticationInteractor(
            coordinator: self,
            modelContext: modelContext,
            shouldAutoNavigateToHome: shouldAutoNavigateToHome
        )
    }

    @ViewBuilder
    func start() -> some View {
        AuthenticationView(interactor: interactor)
    }
}

// MARK: - Presentation

extension DefaultAuthenticationCoordinator {}

// MARK: - Navigation

extension DefaultAuthenticationCoordinator {
    func navigateToLogin() {
        route = .login
    }

    func navigateToRegister() {
        dismissPresented()
        route = .registration
    }
}
