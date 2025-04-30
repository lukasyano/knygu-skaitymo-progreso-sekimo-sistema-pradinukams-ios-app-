import SwiftUI

protocol RegistrationDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayEmail(_ email: String)
    func displayPassword(_ password: String)
    func displayRoleSelection(_ selection: RegistrationModels.RoleSelection)
}

protocol RegistrationViewModel: ObservableObject {
    var isLoading: Bool { get }
    var title: String { get }
    var email: String { get }
    var password: String { get }
    var isDisabled: Bool { get }
    var roleSelection: RegistrationModels.RoleSelection { get }
}

final class DefaultRegistrationViewModel: RegistrationViewModel {
    @Published private(set) var isLoading = false
    @Published private(set) var title: String = "Registracijos forma"
    @Published private(set) var email: String = ""
    @Published private(set) var password: String = ""
    @Published private(set) var isDisabled: Bool = true
    @Published private(set) var roleSelection: RegistrationModels.RoleSelection = .init(
        selected: .child,
        availableRoles: [.child, .parent]
    )
}

// MARK: - Display Logic

extension DefaultRegistrationViewModel: RegistrationDisplayLogic {
    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func displayEmail(_ email: String) {
        self.email = email
        manageDisableState()
    }

    func displayPassword(_ password: String) {
        self.password = password
        manageDisableState()
    }

    func displayRoleSelection(_ selection: RegistrationModels.RoleSelection) {
        roleSelection = selection
    }

    private func manageDisableState() {
        isDisabled = email.isEmpty || password.isEmpty
    }
}
