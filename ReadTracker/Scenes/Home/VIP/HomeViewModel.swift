import SwiftUI

protocol HomeDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayBooks(_ books: [HomeModels.BooksPresentable])
    func displayBookThumbnails(_ presentable: [HomeModels.BooksPresentable])
    func displayBookProgress(_ presentable: [HomeModels.BookProgressPreseentable])
}

protocol HomeViewModel: ObservableObject {
    var title: String { get }
    var isLoading: Bool { get }
    var books: [HomeModels.BooksPresentable] { get }
}

final class DefaultHomeViewModel: HomeViewModel {
    @Published private(set) var title: String = "Biblioteka"
    @Published private(set) var isLoading = true
    @Published private(set) var books: [HomeModels.BooksPresentable] = []
}

// MARK: - Display Logic
extension DefaultHomeViewModel: HomeDisplayLogic {
    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func displayBooks(_ books: [HomeModels.BooksPresentable]) {
        self.books = books
        title = "Tavo bibliotekoje: \(books.count) knyga(os)"
        isLoading = false
    }

    func displayBookThumbnails(_ presentable: [HomeModels.BooksPresentable]) {
        books = presentable
    }
    
    func displayBookProgress(_ presentable: [HomeModels.BookProgressPreseentable]) {
        for progress in presentable {
            if let index = books.firstIndex(where: { $0.id == progress.id }) {
                var updated = books[index]
                updated = HomeModels.BooksPresentable(
                    id: updated.id,
                    title: updated.title,
                    readedPages: progress.readedPages,
                    totalPages: updated.totalPages,
                    image: updated.image
                )
                books[index] = updated
            }
        }
    }

}
