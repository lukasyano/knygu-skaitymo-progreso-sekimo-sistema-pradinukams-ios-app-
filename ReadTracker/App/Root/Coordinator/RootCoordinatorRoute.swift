import Foundation

enum RootCoordinatorRoute: Identifiable, Equatable {
    case splash
    case carousel
    case login
    case register
    case home

    var id: String {
        switch self {
        case .splash:
            "splash"
        case .carousel:
            "carousel"
        case .login:
            "login"
        case .register:
            "register"
        case .home:
            "home"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
