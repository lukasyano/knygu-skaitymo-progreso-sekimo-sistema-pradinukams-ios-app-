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
//    @Environment(\.modelContext) private var modelContext
//    @Query private var items: [Item]
    // VIP
    private weak var coordinator: DefaultAuthenticationCoordinator?
    // Workers

    // Properties
    private lazy var cancelBag = Set<AnyCancellable>()

    // MARK: - Lifecycle

    init(coordinator: DefaultAuthenticationCoordinator) {
        self.coordinator = coordinator
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
            cancelBag.removeAll()

        case .onDisappear: break
        }
    }
}
