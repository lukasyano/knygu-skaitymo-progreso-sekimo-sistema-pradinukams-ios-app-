import Foundation

struct ReadingProgress: Codable {
    let userId: String
    let role: String
    let bookId: String
    var currentPage: Int
    var totalPages: Int?
    var lastUpdated: Date
}
