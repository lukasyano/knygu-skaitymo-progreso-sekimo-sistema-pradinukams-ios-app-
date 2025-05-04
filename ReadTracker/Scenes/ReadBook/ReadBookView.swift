import FirebaseAuth
import SwiftUI

struct ReadBookView: View {
    let url: URL
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    private func dismiss() { presentationMode.wrappedValue.dismiss() }

    var body: some View {
        ZStack(alignment: .bottom) {
            PDFDocumentView(
                url: url) {
                    print($0)
                }

            HoldToDismissButton(action: dismiss)
                .padding(.bottom, 10)
                .padding(.horizontal, 30)
        }
    }

    private func saveProgress(for book: BookEntity, page: Int) {
        let firebaseAuth = Auth.auth()

        let userId = firebaseAuth.getUserID()!
        let role = book.role
        let bookId = book.id

        // Firestore + SwiftData sync here
        let progress = ReadingProgress(
            userId: userId,
            role: role,
            bookId: bookId,
            currentPage: page,
            totalPages: book.totalPages,
            lastUpdated: Date()
        )

        // 🔁 Save locally and remotely
//        ProgressSyncManager.shared.save(progress)
    }
}

// final class ProgressSyncManager {
//    static let shared = ProgressSyncManager()
//
//    private let firestore = Firestore.firestore()
//    private let context = ... // your ModelContext or injected via Resolver
//
//    func save(_ progress: ReadingProgress) {
//        // Save to SwiftData (optional)
//        try? context.insert(progress.toEntity())
//
//        // Save to Firestore
//        let docId = "\(progress.userId)_\(progress.bookId)"
//        try? firestore.collection("readingProgress")
//            .document(docId)
//            .setData(from: progress)
//    }
// }
