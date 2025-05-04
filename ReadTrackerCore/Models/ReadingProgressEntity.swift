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
