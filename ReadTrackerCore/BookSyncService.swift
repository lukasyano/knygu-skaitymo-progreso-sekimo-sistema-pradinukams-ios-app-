import FirebaseFirestore
import SwiftData

/// Synchronizes BookEntity data by clearing local SwiftData store and reloading from Firestore.
final class BookSyncService {
    private let db = Firestore.firestore()
    private let modelContext: ModelContext
    private static let syncLock = NSLock()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Clears all local BookEntity records, then fetches and writes fresh data from Firestore.
    func syncBooks(completion: @escaping ([BookEntity]) -> Void) {
        Self.syncLock.lock()
        defer { Self.syncLock.unlock() }

        // 1. Clear existing local data
        do {
            let fetchDescriptor = FetchDescriptor<BookEntity>()
            let existing = try modelContext.fetch(fetchDescriptor)
            for book in existing {
                modelContext.delete(book)
            }
            try modelContext.save()
            print("🗑️ Cleared all local books.")
        } catch {
            print("⚠️ Failed clearing local books: \(error)")
        }

        // 2. Fetch from Firestore
        db.collection("books").getDocuments { snapshot, error in
            var newBooks: [BookEntity] = []
            guard let documents = snapshot?.documents else {
                print("❌ Firestore fetch error: \(error?.localizedDescription ?? "Unknown error")")
                completion([])
                return
            }

            for doc in documents {
                let data = doc.data()
                guard
                    let id = data["id"] as? String,
                    let title = data["title"] as? String,
                    let role = data["role"] as? String,
                    let pdfURL = data["pdf_url"] as? String
                else {
                    continue
                }

                let entity = BookEntity(id: id, title: title, role: role, pdfURL: pdfURL)
                self.modelContext.insert(entity)
                newBooks.append(entity)
            }

            do {
                try self.modelContext.save()
                print("✅ Saved \(newBooks.count) books from Firestore.")
            } catch {
                print("⚠️ SwiftData save error: \(error)")
            }

            completion(newBooks)
        }
    }
}
