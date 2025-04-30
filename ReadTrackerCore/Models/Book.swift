public struct Book: Codable, Identifiable {
    public var id: String
    public var title: String
    public var audience: String
    public var pdfURL: String

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case audience
        case pdfURL = "pdf_url"
    }
}
