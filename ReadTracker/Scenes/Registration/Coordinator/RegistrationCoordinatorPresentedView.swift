import Foundation

enum RegistrationCoordinatorPresentedView: Identifiable, Equatable {
    case validationError(error: String, onDismiss: () -> Void)
    case infoMessage(message: String, onDismiss: () -> Void)

    var id: String {
        switch self {
        case let .validationError(error, _):
            "validationError_\(error)"
        case let .infoMessage(message, _):
            "infoMessage_\(message)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
