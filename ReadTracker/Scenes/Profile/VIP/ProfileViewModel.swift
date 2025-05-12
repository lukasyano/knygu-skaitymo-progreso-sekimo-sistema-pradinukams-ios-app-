import SwiftUI

protocol ProfileDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func dismissChildCreateCompletion()
}

protocol ProfileViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var isUserCreationActive: Bool { get set }
}

final class DefaultProfileViewModel: ProfileViewModel {
    @Published var isLoading = false
    @Published var isUserCreationActive = false
}

// MARK: - Display Logic

extension DefaultProfileViewModel: ProfileDisplayLogic {
    func dismissChildCreateCompletion() {
        isUserCreationActive = false
    }

    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
