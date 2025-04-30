import Foundation

enum RegistrationCoordinatorRoute: Identifiable, Equatable {
    var id: String {
        switch self {}
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}
