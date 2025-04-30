import Foundation

enum AuthenticationCoordinatorPresentedView: Identifiable, Equatable {
    case failure

    var id: String {
        switch self {
        case .failure:
            "failure_"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
