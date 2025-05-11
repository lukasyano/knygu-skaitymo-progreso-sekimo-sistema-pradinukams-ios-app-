import Combine
import FirebaseFirestore
import Resolver
import SwiftData

class BookSyncService {
    @Injected private var firestoreService: BookFirestoreService
    @Injected private var modelContext: ModelContext

    private let githubBaseURL = "https://api.github.com/repos/lukasyano/Books/contents/"

    func fetchFromGitHubAndAddToFirestore() -> AnyPublisher<Void, Error> {
        fetchGitHubBooks()
            .flatMap { [weak self] books in
                self?.firestoreService.addBooks(books) ?? .empty()
            }
            .eraseToAnyPublisher()
    }

    func syncFirestoreToSwiftData() -> AnyPublisher<Void, Error> {
        firestoreService.fetchAllBooks()
            .receive(on: DispatchQueue.main)
            .tryMap { [weak self] books in
                guard let self else {
                    throw NSError(domain: "Self", code: -1)
                }

                print("🔄 Syncing \(books.count) books from Firestore")

                let existing = try modelContext.fetch(FetchDescriptor<BookEntity>())

                // Update tracking
                var updatedCount = 0
                var insertedCount = 0

                // Update or insert
                for book in books {
                    if let entity = existing.first(where: { $0.id == book.id }) {
                        entity.update(from: book)
                        updatedCount += 1
                    } else {
                        modelContext.insert(book.toEntity())
                        insertedCount += 1
                    }
                }

                // Delete tracking
                let currentIDs = Set(books.map(\.id))
                let toDelete = existing.filter { !currentIDs.contains($0.id) }
                toDelete.forEach { self.modelContext.delete($0) }

                // Save changes
                try modelContext.save()
                print("💾 Sync results: \(insertedCount) new, \(updatedCount) updated, \(toDelete.count) deleted")
            }
            .eraseToAnyPublisher()
    }

    private func fetchGitHubBooks() -> AnyPublisher<[Book], Error> {
        let validRoles: [Role] = [.parent, .child]

        return Publishers.MergeMany(validRoles.map { role in
            fetchGitHubBooks(for: role)
        })
        .collect()
        .map { $0.flatMap { $0 } }
        .eraseToAnyPublisher()
    }

    private func fetchGitHubBooks(for role: Role) -> AnyPublisher<[Book], Error> {
        guard let url = URL(string: "\(githubBaseURL)\(role.rawValue)") else {
            return .empty()
        }
        let config = URLSessionConfiguration.default
        config.urlCache = URLCache(memoryCapacity: 50_000_000, diskCapacity: 1_000_000_000)
        let session = URLSession(configuration: config)

        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [GitHubItem].self, decoder: JSONDecoder())
            .map { items in
                items.filter { $0.name.hasSuffix(".pdf") }
                    .map { item in
                        let title = item.name.replacingOccurrences(of: ".pdf", with: "")
                        let id = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            .replacingOccurrences(of: " ", with: "")
                        return Book(
                            id: id,
                            title: title,
                            role: role,
                            pdfURL: item.pdfURL
                        )
                    }
            }
            .mapError { error -> Error in
                print("❌ GitHub fetch error: \(error)")
                return error
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
