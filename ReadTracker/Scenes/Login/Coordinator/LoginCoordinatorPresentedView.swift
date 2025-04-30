import Foundation

enum LoginCoordinatorPresentedView: Identifiable, Equatable {
    case validationError(error: String)
    case infoMessage(message: String)
    
    var id: String {
        switch self {
        case let .validationError(error):
            "validationError_\(error)"
        case let .infoMessage(message):
            "infoMessage_\(message)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
