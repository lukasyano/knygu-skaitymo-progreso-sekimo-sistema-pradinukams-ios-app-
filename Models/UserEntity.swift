import SwiftData

@Model
class UserEntity {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var role: Role
    var parentID: String?
    var childrensID: [String]
    var points: Int

    // For parents: will hold their children
    @Relationship(deleteRule: .cascade)
    var children: [UserEntity] = []

    // For children: points and a back–link to their parent
    var totalPoints: Int = 0
    @Relationship(deleteRule: .nullify)
    var parent: UserEntity?

    // For children: their reading progress entries
    @Relationship(deleteRule: .cascade)
    var progressEntries: [Progress] = []

    init(
        id: String,
        email: String,
        name: String,
        role: Role,
        parentID: String? = nil,
        childrensID: [String] = [],
        points: Int = 0
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.parentID = parentID
        self.childrensID = childrensID
        self.points = points
    }
}
