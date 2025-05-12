import Foundation

enum HomeCoordinatorPresentedView: Identifiable, Equatable {
    case error(error: String, dismiss: () -> Void)
    case book(book: BookEntity, user: UserEntity)
    case profile(userID: String)

    var id: String {
        switch self {
        case let .error(message, _):
            "error:\(message)"
        case let .book(book, _):
            "book:\(book.id)"
        case let .profile(userID):
            "profile_\(userID)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
