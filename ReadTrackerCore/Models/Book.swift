 struct Book: Codable, Identifiable {
     var id: String
     var title: String
     var role: Role
     var pdfURL: String
}
