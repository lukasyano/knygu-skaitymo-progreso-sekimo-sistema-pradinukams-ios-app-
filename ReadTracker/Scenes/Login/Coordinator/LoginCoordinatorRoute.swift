import Foundation

enum LoginCoordinatorRoute: Identifiable, Equatable {
    case home(userID: String)

    var id: String {
        switch self {
        case let .home(userID): "home_\(userID)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
