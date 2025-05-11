import Combine
import FirebaseFirestore
import Foundation

protocol BookFirestoreService {
    func fetchAllBooks() -> AnyPublisher<[Book], Error>
    func addBooks(_ books: [Book]) -> AnyPublisher<Void, Error>
    func deleteAllBooks() -> AnyPublisher<Void, Error>
}

class DefaultBookFirestoreService: BookFirestoreService {
    private let firestore = Firestore.firestore()

    func fetchAllBooks() -> AnyPublisher<[Book], Error> {
        Future { [weak self] promise in
            self?.firestore.collection("books")
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
                            let role = data["role"] as? String,
                            let pdfURL = data["pdf_url"] as? String
                        else {
                            return nil
                        }

                        return Book(
                            id: doc.documentID,
                            title: title,
                            role: Role(rawValue: role),
                            pdfURL: pdfURL
                        )
                    }

                    promise(.success(books))
                }
        }
        .eraseToAnyPublisher()
    }

    func addBooks(_ books: [Book]) -> AnyPublisher<Void, Error> {
        Publishers.MergeMany(books.map { addBook($0) })
            .collect()
            .map { _ in }
            .eraseToAnyPublisher()
    }

    func deleteAllBooks() -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else { return }

            firestore.collection("books").getDocuments { snapshot, error in
                guard let documents = snapshot?.documents else { return promise(.success(())) }

                let batch = self.firestore.batch()
                documents.forEach { batch.deleteDocument($0.reference) }

                batch.commit { error in
                    if let error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    private func addBook(_ book: Book) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            self?.firestore
                .collection("books")
                .document(book.id)
                .setData(
                    [
                        "id": book.id,
                        "title": book.title,
                        "role": book.role.rawValue,
                        "pdf_url": book.pdfURL
                    ]
                ) { error in
                    if let error {
                        promise(.failure(error))
                    } else {
                        promise(.success(()))
                    }
                }
        }
        .eraseToAnyPublisher()
    }
}
