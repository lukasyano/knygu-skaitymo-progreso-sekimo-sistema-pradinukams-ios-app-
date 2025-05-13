import SwiftData
import Foundation

@Model
class ProgressData: Identifiable {
    @Attribute(.unique) var id: String = UUID().uuidString
    var bookId: String
    var pagesRead: Int
    var totalPages: Int
    var finished: Bool
    var pointsEarned: Int

    @Relationship(deleteRule: .nullify, inverse: \UserEntity.progressData)
    var user: UserEntity?

    init(
        bookId: String,
        pagesRead: Int,
        totalPages: Int,
        finished: Bool,
        pointsEarned: Int
    ) {
        self.bookId = bookId
        self.pagesRead = pagesRead
        self.totalPages = totalPages
        self.finished = finished
        self.pointsEarned = pointsEarned
    }
}
