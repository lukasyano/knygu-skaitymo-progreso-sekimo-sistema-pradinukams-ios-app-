import Foundation

enum HomeCoordinatorPresentedView: Identifiable, Equatable {
    case error(error: String)

    var id: String {
        switch self {
        case let .error(message):
            "error:\(message)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
