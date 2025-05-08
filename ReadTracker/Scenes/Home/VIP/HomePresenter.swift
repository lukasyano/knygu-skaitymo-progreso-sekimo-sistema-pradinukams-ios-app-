import PDFKit
import UIKit

protocol HomePresenter: AnyObject {
    func presentLoading(_ isLoading: Bool)
    func presentBooks(_ entities: [BookEntity])
    func presentUser(_ user: UserEntity)
    func presentBookThumbnails(_ presentable: [HomeModels.BooksPresentable]?)
    func presentProgress(_ progress: [ProgressData])
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
            .init(id: $0.id, title: $0.title, readedPages: .none, totalPages: .none, image: .none)
        })
    }

    func presentUser(_ user: UserEntity) {
        displayLogic?.displayUser(user)
    }

    func presentLoading(_ isLoading: Bool) {
        displayLogic?.displayLoading(isLoading)
    }

    func presentBookThumbnails(_ presentable: [HomeModels.BooksPresentable]?) {
        guard let presentable else { return }
        displayLogic?.displayBookThumbnails(presentable)
    }

    func presentProgress(_ progress: [ProgressData]){
        displayLogic?.displayProgress(progress)
    }
}
