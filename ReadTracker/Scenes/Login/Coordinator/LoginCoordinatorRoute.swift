import Foundation

enum LoginCoordinatorRoute: Identifiable, Equatable {
    case home

    var id: String {
        switch self {
        case .home: "home"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
