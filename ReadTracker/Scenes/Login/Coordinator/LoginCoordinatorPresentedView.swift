import Foundation

enum LoginCoordinatorPresentedView: Identifiable, Equatable {
    case validationError(error: String, onClose: () -> Void)
    case infoMessage(message: String, onClose: () -> Void)

    var id: String {
        switch self {
        case let .validationError(error):
            "validationError_\(error)"
        case let .infoMessage(message, _):
            "infoMessage_\(message)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
