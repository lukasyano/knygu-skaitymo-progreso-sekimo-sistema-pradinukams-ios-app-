import Foundation

enum RegistrationCoordinatorPresentedView: Identifiable, Equatable {
    case validationError(error: String)
    var id: String {
        switch self {
        case let .validationError(error):
            "validationError_\(error)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
