import SwiftUI

protocol HomeDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayBooks(_ books: [HomeModels.BooksPresentable])
    func displayBookThumbnails(_ presentable: [HomeModels.BooksPresentable])
}

protocol HomeViewModel: ObservableObject {
    var title: String { get }
    var isLoading: Bool { get }
    var books: [HomeModels.BooksPresentable] { get }
}

final class DefaultHomeViewModel: HomeViewModel {
    @Published private(set) var title: String = "Tavo knygos"
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
        title = "Tavo knygos: \(books.count)"
        isLoading = false
    }

    func displayBookThumbnails(_ presentable: [HomeModels.BooksPresentable]) {
        books = presentable
    }
}
