import Combine
import FirebaseFirestore
import Resolver
import SwiftData

class BookSyncService {
    private let firestoreService: BookFirestoreService
    private let modelContext: ModelContext

    private let githubBaseURL = "https://api.github.com/repos/lukasyano/Books/contents/"

    init(
        firestoreService: BookFirestoreService = Resolver.resolve(),
        modelContext: ModelContext = Resolver.resolve()
    ) {
        self.firestoreService = firestoreService
        self.modelContext = modelContext
    }

    func fetchFromGitHubAndAddToFirestore() -> AnyPublisher<Void, Error> {
        fetchGitHubBooks()
            .flatMap { [weak self] books in
                self?.firestoreService.addBooks(books) ?? .empty()
            }
            .eraseToAnyPublisher()
    }

    func syncFirestoreToSwiftData() -> AnyPublisher<Void, Error> {
        firestoreService.fetchAllBooks()
            .tryMap { [weak self] books in
                guard let self else { throw NSError(domain: "Self", code: -1) }

                let existing = try self.modelContext.fetch(FetchDescriptor<BookEntity>())

                // Update or insert new
                for book in books {
                    if let entity = existing.first(where: { $0.id == book.id }) {
                        entity.update(from: book)
                    } else {
                        self.modelContext.insert(book.toEntity())
                    }
                }

                // Delete removed
                let currentIDs = Set(books.map(\.id))
                for entity in existing where !currentIDs.contains(entity.id) {
                    self.modelContext.delete(entity)
                }

                try self.modelContext.save()
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

        return URLSession.shared.dataTaskPublisher(for: url)
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
