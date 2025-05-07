protocol BookReaderPresenter: AnyObject {

    func presentLoading(_ isLoading: Bool)
}

final class DefaultBookReaderPresenter {
    private weak var displayLogic: BookReaderDisplayLogic?

    init(displayLogic: BookReaderDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic

extension DefaultBookReaderPresenter: BookReaderPresenter {
    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }

}
