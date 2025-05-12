import SwiftUI

protocol HomeDisplayLogic: AnyObject {
    func displayLoading(_ isLoading: Bool)
}

protocol HomeViewModel: ObservableObject {
    var isLoading: Bool { get }
}

final class DefaultHomeViewModel: HomeViewModel {
    @Published private(set) var isLoading = true
}

// MARK: - Display Logic
extension DefaultHomeViewModel: HomeDisplayLogic {
    func displayLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
}
