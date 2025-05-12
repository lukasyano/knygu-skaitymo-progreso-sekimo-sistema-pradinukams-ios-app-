protocol ProfilePresenter: AnyObject {
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
}
