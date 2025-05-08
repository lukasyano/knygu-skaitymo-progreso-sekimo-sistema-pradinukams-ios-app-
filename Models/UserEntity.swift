import SwiftData
import Foundation

@Model
class UserEntity {
    @Attribute(.unique) var id: String
    var email: String
    var name: String
    var role: Role
    var parentID: String?
    var childrensID: [String]
    var totalPoints: Int
    var progressData: [ProgressData]  // Add this property
    
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

// Add this extension to your UserEntity class
extension UserEntity {
    func withAddedChild(childID: String) -> UserEntity {
        UserEntity(
            id: self.id,
            email: self.email,
            name: self.name,
            role: self.role,
            parentID: self.parentID,
            childrensID: self.childrensID + [childID],
            totalPoints: self.totalPoints
        )
    }
}
