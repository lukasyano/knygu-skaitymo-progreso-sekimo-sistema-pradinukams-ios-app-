import Foundation

enum AuthenticationCoordinatorRoute: Identifiable, Equatable {
    case login
    case registration

    var id: String {
        switch self {
        case .login: "login"
        case .registration: "registration"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
