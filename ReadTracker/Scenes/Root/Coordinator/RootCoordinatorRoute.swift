import Foundation

enum RootCoordinatorRoute: Identifiable, Equatable {
    case carousel
    case authentication
    case home(userID: String)

    var id: String {
        switch self {
        case .carousel:
            "carousel"
        case let .home(userID):
            "home_\(userID)"
        case .authentication:
            "authentication_\(UUID())"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
