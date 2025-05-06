struct Book: Codable, Identifiable {
    var id: String
    var title: String
    var role: Role
    var pdfURL: String
}

extension Book {
    func toEntity() -> BookEntity {
        BookEntity(
            id: id,
            title: title,
            role: role.rawValue,
            pdfURL: pdfURL
        )
    }
}
