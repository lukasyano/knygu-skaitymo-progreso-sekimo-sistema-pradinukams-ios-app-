import SwiftUI

protocol LoginDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayEmail(_ email: String)
    func displayRememberMe(_ isRememberMe: Bool)
    func displayPassword(_ password: String)
}

protocol LoginViewModel: ObservableObject {
    var isLoading: Bool { get }
    var title: String { get }
    var email: String { get }
    var password: String { get }
    var rememberMe: Bool { get }
    var isDisabled: Bool { get }
}

final class DefaultLoginViewModel: LoginViewModel {
    @Published private(set) var isLoading = false
    @Published private(set) var title: String = "Prisijungimo forma"
    @Published private(set) var email: String = ""
    @Published private(set) var password: String = ""
    @Published private(set) var rememberMe: Bool = false
    @Published private(set) var isDisabled: Bool = true
}

// MARK: - Display Logic

extension DefaultLoginViewModel: LoginDisplayLogic {
    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func displayEmail(_ email: String) {
        self.email = email
        manageDisableState()
    }
    
    func displayRememberMe(_ isRememberMe: Bool) {
        self.rememberMe = isRememberMe
    }

    func displayPassword(_ password: String) {
        self.password = password
        manageDisableState()
    }

    private func manageDisableState() {
        isDisabled = email.isEmpty || password.isEmpty
    }
}
