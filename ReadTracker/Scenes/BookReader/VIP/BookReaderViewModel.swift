import SwiftUI

protocol BookReaderDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
    func displayCelebrate()
}

protocol BookReaderViewModel: ObservableObject {
    var isLoading: Bool { get set }
    var shouldCelebrate: Bool { get set }
}

final class DefaultBookReaderViewModel: BookReaderViewModel {
    @Published var isLoading = false
    @Published var shouldCelebrate = false
    @Published var isUserCreationActive = false
}

// MARK: - Display Logic

extension DefaultBookReaderViewModel: BookReaderDisplayLogic {
    func dismissChildCreateCompletion() {
        isUserCreationActive = false
    }

    func displayCelebrate() {
        DispatchQueue.main.async {
            self.shouldCelebrate = true
        }
    }

    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
