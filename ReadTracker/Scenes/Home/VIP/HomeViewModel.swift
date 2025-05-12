import SwiftUI

protocol HomeDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
//    func displayUser(_ user: UserEntity)
//    func displayUserRole(_ role: Role)
//    func displayProgress(_ progress: [ProgressData])
}

protocol HomeViewModel: ObservableObject {
    var title: String { get }
//    var user: UserEntity { get }
//    var progressData: [ProgressData] { get }
    var isLoading: Bool { get }
//    var books: [BookEntity] { get set }
}

final class DefaultHomeViewModel: HomeViewModel {
    @Published private(set) var title: String = "Biblioteka"
    @Published private(set) var user: UserEntity = .init(id: "", email: "", name: "", role: .unknown)
    @Published private(set) var progressData: [ProgressData] = []
    @Published private(set) var isLoading = true
    @Published var books: [BookEntity] = []
}

// MARK: - Display Logic
extension DefaultHomeViewModel: HomeDisplayLogic {
    func displayProgress(_ progress: [ProgressData]) {
        progressData = progress
    }

    func displayUser(_ user: UserEntity) {
        self.user = user
    }

    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
