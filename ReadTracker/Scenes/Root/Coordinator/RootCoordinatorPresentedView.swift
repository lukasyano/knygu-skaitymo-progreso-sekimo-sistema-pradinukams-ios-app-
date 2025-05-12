import Foundation

enum RootCoordinatorPresentedView: Identifiable, Equatable {
    case error(error: String, dismiss: () -> Void)

    var id: String {
        switch self {
        case let .error(message, _):
            "error:\(message)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
