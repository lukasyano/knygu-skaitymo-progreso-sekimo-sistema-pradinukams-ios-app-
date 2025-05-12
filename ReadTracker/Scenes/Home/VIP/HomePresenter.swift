protocol HomePresenter: AnyObject {
    func presentLoading(_ isLoading: Bool)
}

final class DefaultHomePresenter {
    private weak var displayLogic: HomeDisplayLogic?

    init(displayLogic: HomeDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic
extension DefaultHomePresenter: HomePresenter {
    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }
}
