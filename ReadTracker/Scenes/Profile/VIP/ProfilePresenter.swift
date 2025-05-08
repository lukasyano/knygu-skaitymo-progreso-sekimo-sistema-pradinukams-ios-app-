protocol ProfilePresenter: AnyObject {
    func presentUser(_ user: UserEntity)
    func presentChilds(_ childs: [UserEntity])
    func dismissChildCreateCompletion()
    func presentProgress(_ progress: [ProgressData])

    func presentLoading(_ isLoading: Bool)
}

final class DefaultProfilePresenter {
    private weak var displayLogic: ProfileDisplayLogic?

    init(displayLogic: ProfileDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic

extension DefaultProfilePresenter: ProfilePresenter {
    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }

    func presentUser(_ user: UserEntity) {
        displayLogic?.displayUser(user)
    }

    func presentChilds(_ childs: [UserEntity]) {
        displayLogic?.displayChilds(childs)
    }

    func dismissChildCreateCompletion() {
        displayLogic?.dismissChildCreateCompletion()
    }

    func presentProgress(_ progress: [ProgressData]) {
        displayLogic?.displayProgress(progress)
    }

//
//    func presentName(_ name: String) {
//        displayLogic?.displayName(name)
//    }
//
//    func presentPassword(_ password: String) {
//        displayLogic?.displayPassword(password)
//    }
}
