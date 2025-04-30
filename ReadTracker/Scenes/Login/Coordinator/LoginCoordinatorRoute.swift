import Foundation

enum LoginCoordinatorRoute: Identifiable, Equatable {
    case main

    var id: String {
        switch self {
        case .main: "main"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
