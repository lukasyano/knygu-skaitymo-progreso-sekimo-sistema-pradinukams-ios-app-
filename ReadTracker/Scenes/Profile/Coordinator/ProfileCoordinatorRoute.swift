import Foundation

enum ProfileCoordinatorRoute: Identifiable, Equatable {
    case login(String)

    var id: String {
        switch self {
        case let .login(email):
            "login_\(email)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
