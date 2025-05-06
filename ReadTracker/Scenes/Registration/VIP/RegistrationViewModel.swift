import SwiftUI

protocol RegistrationDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayEmail(_ email: String)
    func displayName(_ name: String)
    func displayPassword(_ password: String)
}

protocol RegistrationViewModel: ObservableObject {
    var isLoading: Bool { get }
    var title: String { get }
    var email: String { get }
    var name: String { get }
    var password: String { get }
    var isDisabled: Bool { get }
}

final class DefaultRegistrationViewModel: RegistrationViewModel {
    @Published private(set) var isLoading = false
    @Published private(set) var title: String = "Naujos tėvų rolės registracijos forma"
    @Published private(set) var email: String = ""
    @Published private(set) var name: String = ""
    @Published private(set) var password: String = ""
    @Published private(set) var isDisabled: Bool = true
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

    func displayName(_ name: String) {
        self.name = name
        manageDisableState()
    }

    func displayPassword(_ password: String) {
        self.password = password
        manageDisableState()
    }

    private func manageDisableState() {
        isDisabled = email.isEmpty || password.isEmpty || name.isEmpty
    }
}
