import Foundation

enum RootCoordinatorRoute: Identifiable, Equatable {
    case carousel
    case authentication
    case home

    var id: String {
        switch self {
        case .carousel:
            "carousel"
        case .home:
            "home"
        case .authentication:
            "authentication)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
