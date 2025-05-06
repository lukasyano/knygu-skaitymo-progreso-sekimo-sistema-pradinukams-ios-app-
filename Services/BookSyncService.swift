import Combine
import FirebaseFirestore
import SwiftData
import Resolver

class BookSyncService {
    private let db = Firestore.firestore()
    private let modelContext: ModelContext

    init(modelContext: ModelContext = Resolver.resolve()) {
        self.modelContext = modelContext
    }

    /// Synchronizes remote GitHub and Firestore data into local SwiftData entities.
    /// Returns a publisher with the newly added entities.
    func syncBooks() -> AnyPublisher<[BookEntity], Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(NSError(domain: "SyncService", code: -1)))
                return
            }

            let roles: [Role] = [.parent, .child]
            var allNewBooks: [BookEntity] = []
            let syncQueue = DispatchQueue(label: "bookSyncQueue")
            let group = DispatchGroup()

            for role in roles {
                guard let url = URL(string: "https://api.github.com/repos/lukasyano/Books/contents/\(role.rawValue)") else { continue }

                group.enter()
                URLSession.shared.dataTask(with: url) { data, _, _ in
                    defer { group.leave() }

                    guard
                        let data = data,
                        let items = try? JSONDecoder().decode([GitHubItem].self, from: data)
                    else {
                        return
                    }

                    let books = items.filter { $0.name.hasSuffix(".pdf") }.map { item -> Book in
                        let title = item.name.replacingOccurrences(of: ".pdf", with: "")
                        let id = title.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "")
                        return Book(id: id, title: title, role: role, pdfURL: item.pdfURL)
                    }

                    DispatchQueue.main.async {
                        do {
                            let existing = try self.modelContext.fetch(FetchDescriptor<BookEntity>())
                            let existingIDs = Set(existing.map { $0.id })

                            for book in books where !existingIDs.contains(book.id) {
                                let entity = BookEntity(id: book.id,
                                                        title: book.title,
                                                        role: book.role.rawValue,
                                                        pdfURL: book.pdfURL)
                                self.modelContext.insert(entity)
                                syncQueue.sync { allNewBooks.append(entity) }

                                self.db.collection("books").document(book.id)
                                    .setData([
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
                        } catch {
                            print("❌ SwiftData error: \(error)")
                        }
                    }
                }.resume()
            }

            group.notify(queue: .main) {
                promise(.success(allNewBooks))
            }
        }
        .eraseToAnyPublisher()
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
