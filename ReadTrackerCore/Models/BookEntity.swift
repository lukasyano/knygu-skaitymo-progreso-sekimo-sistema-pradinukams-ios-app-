import Foundation
import SwiftData

@Model
class BookEntity {
    @Attribute(.unique) var id: String
    var title: String
    var role: String
    var pdfURL: String
    var localFilePath: String?

    init(id: String, title: String, role: String, pdfURL: String, localFilePath: String? = nil) {
        self.id = id
        self.title = title
        self.role = role
        self.pdfURL = pdfURL
        self.localFilePath = localFilePath
    }
}
