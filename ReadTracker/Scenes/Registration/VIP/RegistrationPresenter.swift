protocol RegistrationPresenter: AnyObject {
    func presentEmail(_ email: String)
    func presentName(_ name: String)
    func presentPassword(_ password: String)
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

    func presentName(_ name: String) {
        displayLogic?.displayName(name)
    }

    func presentPassword(_ password: String) {
        displayLogic?.displayPassword(password)
    }
}
