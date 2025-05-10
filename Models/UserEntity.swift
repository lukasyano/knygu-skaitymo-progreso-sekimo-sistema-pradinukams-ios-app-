import Foundation
import SwiftData

@Model
class UserEntity {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var role: Role
    var parentID: String?
    var childrensID: [String]
    var totalPoints: Int
    var progressData: [ProgressData]

    init(
        id: String,
        email: String,
        name: String,
        role: Role,
        parentID: String? = nil,
        childrensID: [String] = [],
        totalPoints: Int = 0,
        progressData: [ProgressData] = []
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.role = role
        self.parentID = parentID
        self.childrensID = childrensID
        self.totalPoints = totalPoints
        self.progressData = progressData
    }
}

struct ProgressData: Codable, Identifiable {
    var id: String = UUID().uuidString
    var bookId: String
    var pagesRead: Int
    var totalPages: Int
    var finished: Bool
    var pointsEarned: Int
}

extension UserEntity {
    func withAddedChild(childID: String) -> UserEntity {
        UserEntity(
            id: id,
            email: email,
            name: name,
            role: role,
            parentID: parentID,
            childrensID: childrensID + [childID],
            totalPoints: totalPoints
        )
    }
}
