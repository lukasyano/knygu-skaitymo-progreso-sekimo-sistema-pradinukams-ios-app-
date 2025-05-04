import Combine
import Resolver
import SwiftData
import SwiftUI

protocol AuthenticationInteractor: AnyObject {
    func viewDidChange(_ type: ViewDidChangeType)
    func tapLogin()
    func tapRegister()
}

final class DefaultAuthenticationInteractor {
    private weak var coordinator: DefaultAuthenticationCoordinator?

    private let modelContext: ModelContext

    init(
        coordinator: DefaultAuthenticationCoordinator,
        modelContext: ModelContext,
        shouldAutoNavigateToHome: Bool
    ) {
        self.coordinator = coordinator
        self.modelContext = modelContext
        if shouldAutoNavigateToHome {
            coordinator.navigateToLogin()
        }
    }
}

// MARK: - Business Logic

extension DefaultAuthenticationInteractor: AuthenticationInteractor {
    func tapLogin() {
        coordinator?.navigateToLogin()
    }

    func tapRegister() {
        coordinator?.navigateToRegister()
    }

    // MARK: - View Did Change

    func viewDidChange(_ type: ViewDidChangeType) {
        switch type {
        case .onAppear:
            break

        case .onDisappear:
            break
        }
    }
}
