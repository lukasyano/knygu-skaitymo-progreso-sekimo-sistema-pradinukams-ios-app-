import FirebaseFirestore
import Foundation

struct ReadingSession: Codable {
    @DocumentID var id: String?
    let bookId: String
    let startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var pagesRead: [PageRead]

    enum CodingKeys: String, CodingKey {
        case id
        case bookId
        case startTime
        case endTime
        case duration
        case pagesRead
    }
}

struct PageRead: Codable {
    let pageNumber: Int
    let timestamp: Date
}
