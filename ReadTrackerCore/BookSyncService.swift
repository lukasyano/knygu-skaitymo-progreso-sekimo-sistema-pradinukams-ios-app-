import FirebaseFirestore
import Foundation
import SwiftData

class BookSyncService {
    private let db = Firestore.firestore()
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func syncBooks(completion: @escaping ([BookEntity]) -> Void) {
        let roles: [Role] = [.parent, .child]
        var allNewBooks: [BookEntity] = []
        let syncQueue = DispatchQueue(label: "bookSyncQueue")
        let group = DispatchGroup()

        for role in roles {
            guard let url = URL(string: "https://api.github.com/repos/lukasyano/Books/contents/\(role.rawValue)") else { continue }

            group.enter()
            URLSession.shared.dataTask(with: url) { data, _, _ in
                defer { group.leave() }

                guard let data = data else {
                    print("❌ No data for role: \(role.rawValue)")
                    return
                }

                let items: [GitHubItem]
                do {
                    items = try JSONDecoder().decode([GitHubItem].self, from: data)
                } catch {
                    print("❌ Decoding error for role \(role.rawValue): \(error)")
                    return
                }

                let books = items
                    .filter { $0.name.hasSuffix(".pdf") }
                    .map {
                        let title = ($0.name.removingPercentEncoding ?? $0.name).replacingOccurrences(of: ".pdf", with: "")
                        let id = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        return Book(id: id, title: title, role: role, pdfURL: $0.pdfURL)
                    }

                DispatchQueue.main.async {
                    do {
                        let existing = try self.modelContext.fetch(FetchDescriptor<BookEntity>())
                        let existingIDs = Set(existing.map { $0.id })

                        for book in books where !existingIDs.contains(book.id) {
                            let entity = BookEntity(
                                id: book.id,
                                title: book.title,
                                role: book.role.rawValue,
                                pdfURL: book.pdfURL
                            )
                            self.modelContext.insert(entity)

                            syncQueue.sync {
                                allNewBooks.append(entity)
                            }

                            self.db.collection("books").document(book.id).setData([
                                "id": book.id,
                                "title": book.title,
                                "role": book.role.rawValue,
                                "pdf_url": book.pdfURL
                            ]) { error in
                                if let error = error {
                                    print("❌ Firestore write error for \(book.id): \(error)")
                                }
                            }
                        }

                        try self.modelContext.save()
                        print("🔎 Book count after \(role.rawValue): \(try self.modelContext.fetch(FetchDescriptor<BookEntity>()).count)")
                    } catch {
                        print("❌ SwiftData error: \(error)")
                    }
                }

            }.resume()
        }

        group.notify(queue: .main) {
            completion(allNewBooks)
        }
    }

    private struct GitHubItem: Codable {
        let name: String
        let pdfURL: String

        enum CodingKeys: String, CodingKey {
            case name
            case pdfURL = "download_url"
        }
    }
}
