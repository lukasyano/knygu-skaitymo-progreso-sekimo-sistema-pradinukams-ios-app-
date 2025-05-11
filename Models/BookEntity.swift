import Foundation
import SwiftData
import UIKit

@Model
class BookEntity {
    @Attribute(.unique) var id: String
    var title: String
    var role: String
    var pdfURL: String
    var totalPages: Int?
    var fileURL: URL?
    var thumbnailData: Data?

    init(
        id: String,
        title: String,
        role: String,
        pdfURL: String,
        totalPages: Int? = nil,
        fileURL: URL? = nil,
        thumbnailData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.role = role
        self.pdfURL = pdfURL
        self.totalPages = totalPages
        self.fileURL = fileURL
        self.thumbnailData = thumbnailData
    }
}

extension BookEntity {
    func update(from book: Book) {
        title = book.title
        role = book.role.rawValue
        pdfURL = book.pdfURL
    }
}
