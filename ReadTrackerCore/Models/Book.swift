public struct Book: Codable, Identifiable {
    public var id: String
    public var title: String
    public var role: Role
    public var pdfURL: String
}
