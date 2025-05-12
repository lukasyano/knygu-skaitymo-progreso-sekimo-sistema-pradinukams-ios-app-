import Foundation

enum AuthenticationCoordinatorPresentedView: Identifiable, Equatable {
    case failure(String)
    case info(String)

    var id: String {
        switch self {
        case .failure:
            "failure_"
        case .info:
            "info_"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
