import SwiftUI

protocol ProfileDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayUser(_ user: UserEntity)
    func displayChilds(_ childs: [UserEntity])
    func dismissChildCreateCompletion()
    func displayProgress(_ progress: [ProgressData])
}

protocol ProfileViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var isUserCreationActive: Bool { get set }
    var user: UserEntity { get }
    var childs: [UserEntity] { get }
    var progressData: [ProgressData] { get }

}

final class DefaultProfileViewModel: ProfileViewModel {
    @Published var isLoading = false
    @Published var isUserCreationActive = false
    @Published private(set) var user: UserEntity = .init(id: "", email: "", name: "", role: .unknown)
    @Published private(set) var childs: [UserEntity] = .init()
    @Published private(set) var progressData: [ProgressData] = []

}

// MARK: - Display Logic

extension DefaultProfileViewModel: ProfileDisplayLogic {
    func displayProgress(_ progress: [ProgressData]) {
        progressData = progress
    }

    func dismissChildCreateCompletion() {
        isUserCreationActive = false
    }

    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

    func displayUser(_ user: UserEntity) {
        self.user = user
    }

    func displayChilds(_ childs: [UserEntity]) {
        self.childs = childs
    }

}
