@testable import ReadTracker

class MockLoginPresenter: LoginPresenter {
    func presentRememberMe(_ isRememberMe: Bool) {}

    var presentedEmails: [String] = []
    var presentedPasswords: [String] = []
    var loadingStates: [Bool] = []

    func presentEmail(_ email: String) {
        presentedEmails.append(email)
    }

    func presentPassword(_ password: String) {
        presentedPasswords.append(password)
    }

    func presentLoading(_ loading: Bool) {
        loadingStates.append(loading)
    }
}
