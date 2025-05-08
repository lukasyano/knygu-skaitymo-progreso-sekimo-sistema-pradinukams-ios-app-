import SwiftUI

protocol HomeDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayBooks(_ books: [HomeModels.BooksPresentable])
    func displayUser(_ user: UserEntity)
    func displayBookThumbnails(_ presentable: [HomeModels.BooksPresentable])
    func displayProgress(_ progress: [ProgressData])
}

protocol HomeViewModel: ObservableObject {
    var title: String { get }
    var user: UserEntity { get }
    var progressData: [ProgressData] { get }
    var isLoading: Bool { get }
    var books: [HomeModels.BooksPresentable] { get }
}

final class DefaultHomeViewModel: HomeViewModel {
    @Published private(set) var title: String = "Biblioteka"
    @Published private(set) var user: UserEntity = .init(id: "", email: "", name: "", role: .unknown)
    @Published private(set) var progressData: [ProgressData] = []
    @Published private(set) var isLoading = true
    @Published private(set) var books: [HomeModels.BooksPresentable] = []
}

// MARK: - Display Logic
extension DefaultHomeViewModel: HomeDisplayLogic {
    func displayProgress(_ progress: [ProgressData]) {
        self.progressData = progress
    }
    
    func displayUser(_ user: UserEntity) {
        self.user = user
    }

    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func displayBooks(_ books: [HomeModels.BooksPresentable]) {
        DispatchQueue.main.async { [self] in
            self.books = books
            title = "Tavo bibliotekoje: \(books.count) knyga(os)"
            isLoading = false
        }
    }

    func displayBookThumbnails(_ presentable: [HomeModels.BooksPresentable]) {
        DispatchQueue.main.async { [self] in
            books = presentable
        }
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
