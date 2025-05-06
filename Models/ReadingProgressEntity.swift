import Foundation
import SwiftData

@Model
class ReadingProgressEntity {
    @Attribute(.unique) var id: String = ""
    var userId: String
    var role: String
    var bookId: String
    var currentPage: Int
    var totalPages: Int?
    var lastUpdated: Date

    // Link back to the child and the book
    @Relationship(deleteRule: .nullify)
    var child: UserEntity?
    @Relationship(deleteRule: .nullify)
    var book: BookEntity?

    init(
        id: String,
        userId: String,
        role: String,
        bookId: String,
        currentPage: Int,
        totalPages: Int? = nil,
        lastUpdated: Date
    ) {
        self.id = id
        self.userId = userId
        self.role = role
        self.bookId = bookId
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.lastUpdated = lastUpdated
    }
}

@Model
final class Progress {
    @Attribute(.unique) var id: String = UUID().uuidString
    var pagesRead: Int
    var totalPages: Int
    var finished: Bool
    var pointsEarned: Int

    // Link back to the child and the book
    @Relationship(deleteRule: .nullify)
    var child: UserEntity?
    @Relationship(deleteRule: .nullify)
    var book: BookEntity?

    init(pagesRead: Int, totalPages: Int, finished: Bool, pointsEarned: Int) {
        self.pagesRead = pagesRead
        self.totalPages = totalPages
        self.finished = finished
        self.pointsEarned = pointsEarned
    }
}
