import PDFKit
import UIKit

protocol HomePresenter: AnyObject {
    func presentLoading(_ isLoading: Bool)
    func presentBooks(_ books: [HomeModels.BooksPresentable])
}

final class DefaultHomePresenter {
    private weak var displayLogic: HomeDisplayLogic?

    init(displayLogic: HomeDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic
extension DefaultHomePresenter: HomePresenter {
    func presentBooks(_ books: [HomeModels.BooksPresentable]) {
        print("presentBooks: \(books.count)")
        displayLogic?.displayBooks(books)
    }

    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }
}
