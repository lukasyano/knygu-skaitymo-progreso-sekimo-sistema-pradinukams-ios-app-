import SwiftUI

protocol BookReaderDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)

}

protocol BookReaderViewModel: ObservableObject {
    var isLoading: Bool { get set }


}

final class DefaultBookReaderViewModel: BookReaderViewModel {
    @Published var isLoading = false
    @Published var isUserCreationActive = false
    @Published private(set) var user: UserEntity = .init(id: "", email: "", name: "", role: .unknown)
    @Published private(set) var childs: [UserEntity] = .init()

}

// MARK: - Display Logic

extension DefaultBookReaderViewModel: BookReaderDisplayLogic {
    func dismissChildCreateCompletion() {
        isUserCreationActive = false
    }

    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }

}
