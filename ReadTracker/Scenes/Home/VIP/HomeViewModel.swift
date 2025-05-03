import SwiftUI

protocol HomeDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayBooks(_ books: [HomeModels.BooksPresentable])
    func displayBookThumbnail(_ presentable: HomeModels.BooksPresentable)
}

protocol HomeViewModel: ObservableObject {
    var title: String { get }
    var isLoading: Bool { get }
    var books: [HomeModels.BooksPresentable] { get }
}

final class DefaultHomeViewModel: HomeViewModel {
    @Published private(set) var title: String = "Tavo knygų sąrašas"
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
        isLoading = false
    }

    func displayBookThumbnail(_ presentable: HomeModels.BooksPresentable) {
        guard let index = books.firstIndex(where: { $0.id == presentable.id }) else { return }

        books[index] = presentable
    }
}
