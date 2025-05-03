import Foundation

enum HomeCoordinatorRoute: Identifiable, Equatable {
    case book(URL)

    var id: String {
        switch self {
        case let .book(url):
            "book\(url)"
        }
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
