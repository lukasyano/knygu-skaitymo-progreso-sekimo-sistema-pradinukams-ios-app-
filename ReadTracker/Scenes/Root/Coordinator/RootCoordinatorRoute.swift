import Foundation

enum RootCoordinatorRoute: Identifiable, Equatable {
    case carousel
    case login
    case authentication
    case register
    case home(String)

    var id: String {
        switch self {
        case .carousel:
            "carousel"
        case .login:
            "login"
        case .register:
            "register"
        case let .home(userID):
            "home\(userID)"
        case .authentication:
            "authentication"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
