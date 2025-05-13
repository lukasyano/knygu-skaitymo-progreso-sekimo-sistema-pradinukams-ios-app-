import Foundation
import SwiftData

@Model
class UserEntity {
    @Attribute(.unique) var id: String
//    var userUID: String
    var email: String
    var name: String
    var role: Role
    var totalPoints: Int

    // Firestore-compatible fields
    var parentID: String?
    var childrensID: String = ""
    // Relationships
    @Relationship(deleteRule: .cascade)
    var progressData = [ProgressData]()

    @Relationship(deleteRule: .nullify)
    var parent: UserEntity?

    @Relationship(deleteRule: .nullify, inverse: \UserEntity.parent)
    var children = [UserEntity]()

    init(
       // userUID: String,
        id: String,
        email: String,
        name: String,
        role: Role,
        parentID: String? = nil,
        childrensID: String = "",
        totalPoints: Int = 0
    ) {
       // self.userUID = userUID
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.parentID = parentID
        self.childrensID = childrensID
        self.totalPoints = totalPoints
    }
}

extension UserEntity {
    func updateChildrenIDs() {
        childrensID = children.map { $0.id }.joined(separator: ",")
    }

    func withAddedChild(_ child: UserEntity) -> UserEntity {
        child.parentID = id
        children.append(child)
        childrensID.append(child.id)
        return self
    }

    func deleteChild(_ child: UserEntity) {
        children.removeAll { $0.id == child.id }
        updateChildrenIDs()
        child.parentID = nil
    }

    func getChildrenIDs() -> [String] {
        return childrensID.isEmpty ? [] : childrensID.components(separatedBy: ",")
    }
}
