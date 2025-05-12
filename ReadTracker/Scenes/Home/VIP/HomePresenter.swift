protocol HomePresenter: AnyObject {
    func presentLoading(_ isLoading: Bool)
//    func presentUser(_ user: UserEntity)
//    func presentUserRole(_ role: Role)
//    func presentProgress(_ progress: [ProgressData])
}

final class DefaultHomePresenter {
    private weak var displayLogic: HomeDisplayLogic?

    init(displayLogic: HomeDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic
extension DefaultHomePresenter: HomePresenter {
//    func presentUser(_ user: UserEntity) {
//        displayLogic?.displayUser(user)
//    }
//    
//    func presentUserRole(_ role: Role) {
//        displayLogic?.displayUserRole(role)
//    }
//

    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }

//    func presentProgress(_ progress: [ProgressData]) {
//        displayLogic?.displayProgress(progress)
//    }
}
