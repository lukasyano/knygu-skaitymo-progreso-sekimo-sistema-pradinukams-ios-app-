protocol LoginPresenter: AnyObject {
    func presentEmail(_ email: String)
    func presentPassword(_ password: String)
    func presentRememberMe(_ isRememberMe: Bool)
    func presentLoading(_ isLoading: Bool)
}

final class DefaultLoginPresenter {
    private weak var displayLogic: LoginDisplayLogic?

    init(displayLogic: LoginDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic

extension DefaultLoginPresenter: LoginPresenter {
    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }
    
    func presentRememberMe(_ isRememberMe: Bool){
        displayLogic?.displayRememberMe(isRememberMe)
    }

    func presentEmail(_ email: String) {
        displayLogic?.displayEmail(email)
    }

    func presentPassword(_ password: String) {
        displayLogic?.displayPassword(password)
    }
}
