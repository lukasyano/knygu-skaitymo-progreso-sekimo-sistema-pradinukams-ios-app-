import Foundation

enum HomeCoordinatorPresentedView: Identifiable, Equatable {
    case error(error: String, dismiss: () -> Void)
    case book(url: URL)

    var id: String {
        switch self {
        case let .error(message, _):
            "error:\(message)"
        case let .book(url: url):
            "book:\(url)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
