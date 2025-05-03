import PDFKit
import UIKit

protocol HomePresenter: AnyObject {
    func presentLoading(_ isLoading: Bool)
    func presentBooks(_ entities: [BookEntity])
    func presentBookThumbnails(_ presentable: [HomeModels.BooksPresentable])
}

final class DefaultHomePresenter {
    private weak var displayLogic: HomeDisplayLogic?

    init(displayLogic: HomeDisplayLogic) {
        self.displayLogic = displayLogic
    }
}

// MARK: - Presentation Logic
extension DefaultHomePresenter: HomePresenter {
    func presentBooks(_ entities: [BookEntity]) {
        displayLogic?.displayBooks(entities.map {
            .init(id: $0.id, title: $0.title, image: .none)
        })
    }

    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }

    func presentBookThumbnails(_ presentable: [HomeModels.BooksPresentable]) {
        displayLogic?.displayBookThumbnails(presentable)
    }
}
