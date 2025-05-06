import Foundation

enum AuthenticationCoordinatorRoute: Identifiable, Equatable, Hashable {
    case login
    case registration

    var id: String {
        switch self {
        case .login: "login_\(UUID())"
        case .registration: "registration_\(UUID())"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
