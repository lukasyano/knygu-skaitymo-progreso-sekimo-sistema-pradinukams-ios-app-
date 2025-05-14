import Foundation

struct ReadingSession: Codable {
    var id: String?
    var bookId: String
    var startTime: Date
    var endTime: Date
    var duration: TimeInterval
    var pages: [PageRead]
    
    enum CodingKeys: String, CodingKey {
        case id
        case bookId
        case startTime
        case endTime
        case duration
        case pages
    }
}

struct PageRead: Codable {
    var pageNumber: Int
    var timestamp: Date
}
