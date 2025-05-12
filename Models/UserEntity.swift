import Foundation
import SwiftData

@Model
class UserEntity {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var role: Role
    var totalPoints: Int

    // Firestore-compatible fields
    var parentID: String?
    var childrensID: [String]

    // Relationships
    @Relationship(deleteRule: .cascade)
    var progressData = [ProgressData]()

    @Relationship(deleteRule: .nullify)
    var parent: UserEntity?

    @Relationship(deleteRule: .nullify, inverse: \UserEntity.parent)
    var children = [UserEntity]()

    init(
        id: String,
        email: String,
        name: String,
        role: Role,
        parentID: String? = nil,
        childrensID: [String] = [],
        totalPoints: Int = 0
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.parentID = parentID
        self.childrensID = childrensID
        self.totalPoints = totalPoints
    }
}

@Model
class ProgressData: Identifiable {
    @Attribute(.unique) var id: String
    var bookId: String
    var pagesRead: Int
    var totalPages: Int
    var finished: Bool
    var pointsEarned: Int

    @Relationship(deleteRule: .nullify, inverse: \UserEntity.progressData)
    var user: UserEntity?

    init(
        id: String = UUID().uuidString,
        bookId: String,
        pagesRead: Int,
        totalPages: Int,
        finished: Bool,
        pointsEarned: Int
    ) {
        self.id = id
        self.bookId = bookId
        self.pagesRead = pagesRead
        self.totalPages = totalPages
        self.finished = finished
        self.pointsEarned = pointsEarned
    }
}

extension UserEntity {
    func updateChildrenIDs() {
        childrensID = children.map { $0.id }
    }

    func withAddedChild(_ child: UserEntity) -> UserEntity {
        child.parentID = id
        children.append(child)
        childrensID.append(child.id)
        return self
    }

    func deleteChild(_ child: UserEntity) {
        children.removeAll { $0.id == child.id }
        childrensID.removeAll { $0 == child.id }
        child.parentID = nil
    }
}
