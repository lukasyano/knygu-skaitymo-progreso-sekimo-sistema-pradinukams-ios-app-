import SwiftUI

protocol HomeDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayBooks(_ books: [HomeModels.BooksPresentable])
}

protocol HomeViewModel: ObservableObject {
    var title: String { get }
    var isLoading: Bool { get }
    var books: [HomeModels.BooksPresentable] { get }
}

final class DefaultHomeViewModel: HomeViewModel {
    @Published private(set) var title: String = ""
    @Published private(set) var isLoading = false
    @Published private(set) var books: [HomeModels.BooksPresentable] = []
}

// MARK: - Display Logic
extension DefaultHomeViewModel: HomeDisplayLogic {
    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func displayBooks(_ books: [HomeModels.BooksPresentable]) {
        self.books = books
    }
}
