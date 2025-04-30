protocol RegistrationPresenter: AnyObject {
    func presentEmail(_ email: String)
    func presentPassword(_ password: String)
    func presentRoleSelection(_ selection: RegistrationModels.RoleSelection)
    func presentLoading(_ isLoading: Bool)
}

final class DefaultRegistrationPresenter {
    private weak var displayLogic: RegistrationDisplayLogic?

    init(displayLogic: RegistrationDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic

extension DefaultRegistrationPresenter: RegistrationPresenter {
    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }

    func presentEmail(_ email: String) {
        displayLogic?.displayEmail(email)
    }

    func presentPassword(_ password: String) {
        displayLogic?.displayPassword(password)
    }

    func presentRoleSelection(_ selection: RegistrationModels.RoleSelection) {
        displayLogic?.displayRoleSelection(selection)
    }
}
