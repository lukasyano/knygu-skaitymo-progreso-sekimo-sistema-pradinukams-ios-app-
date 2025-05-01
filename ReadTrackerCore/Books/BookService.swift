import Combine
import FirebaseFirestore
import Foundation

public protocol BookFirestoreService {
    func fetchBooks(for role: Role) -> AnyPublisher<[Book], Error>
}

public class DefaultBookFirestoreService: BookFirestoreService {
    private let firestore = Firestore.firestore()

    public init() {}

    public func fetchBooks(for role: Role) -> AnyPublisher<[Book], Error> {
        Future { promise in
            self.firestore.collection("books")
                .whereField("role", isEqualTo: role.rawValue)
                .getDocuments { snapshot, error in

                    if let error = error {
                        print("❌ Failed to fetch books: \(error.localizedDescription)")
                        promise(.failure(error))
                        return
                    }

                    guard let documents = snapshot?.documents else {
                        promise(.success([]))
                        return
                    }

                    let books: [Book] = documents.compactMap { doc in
                        let data = doc.data()
                        guard
                            let title = data["title"] as? String,
                            let audience = data["role"] as? String,
                            let pdfURL = data["pdf_url"] as? String
                        else {
                            return nil
                        }

                        return Book(id: doc.documentID, title: title, audience: audience, pdfURL: pdfURL)
                    }

                    promise(.success(books))
                }
        }
        .eraseToAnyPublisher()
    }
}
