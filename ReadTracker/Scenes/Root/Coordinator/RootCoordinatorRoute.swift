import Foundation

enum RootCoordinatorRoute: Identifiable, Equatable {
    case carousel
    case authentication
    case home(user: UserEntity)

    var id: String {
        switch self {
        case .carousel:
            "carousel"
        case .home:
            "home_\(UUID())"
        case .authentication:
            "authentication_\(UUID())"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
