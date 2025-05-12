import SwiftData
import SwiftUI

struct BookItemView: View {
    let book: BookEntity
    let user: UserEntity
    let onBookClicked: () -> Void

    private var progressData: ProgressData? {
        user.progressData.first { $0.bookId == book.id }
    }

    private var pagesRead: Int {
        progressData?.pagesRead ?? 0
    }

    private var totalPages: Int {
        book.totalPages ?? 0
    }

    private var progress: CGFloat {
        totalPages > 0 ? CGFloat(pagesRead) / CGFloat(totalPages) : 0
    }

    private var progressText: String {
        pagesRead > 0 ? "Skaitoma" : "Nepradėta"
    }

    private var progressColor: Color {
        pagesRead > 0 ? .blue : .gray.opacity(0.5)
    }

    var body: some View {
        HStack(spacing: 12) {
            bookCoverImage
                .frame(width: 80, height: 100)
                .cornerRadius(6)
                .clipped()

            VStack(alignment: .leading, spacing: 6) {
                bookTitle
                pagesReadIndicator
                progressBar
                statusChip
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                onBookClicked()
            }
        }
    }

    private var bookCoverImage: some View {
        ZStack {
            if let data = book.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.2))
                Image(systemName: "book")
                    .resizable()
                    .scaledToFit()
                    .padding(10)
                    .foregroundColor(.gray)
            }
        }
    }

    private var bookTitle: some View {
        Text(book.title)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }

    private var pagesReadIndicator: some View {
        Text("\(pagesRead) iš \(totalPages) puslapių")
            .font(.footnote)
            .foregroundColor(.gray)
    }

    private var progressBar: some View {
        ProgressView(value: progress)
            .frame(height: 6)
            .accentColor(progressColor)
            .clipShape(Capsule())
            .animation(.easeInOut(duration: 0.4), value: progress)
    }

    private var statusChip: some View {
        Text(progressText)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(progress > 0 ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
            )
            .foregroundColor(progress > 0 ? .blue : .gray)
            .overlay(
                Capsule()
                    .stroke(progress > 0 ? Color.blue : Color.gray, lineWidth: 1)
            )
    }
}

#Preview {
    BookItemView(
        book: BookEntity(
            id: "1",
            title: "The Little Prince",
            role: "child",
            pdfURL: "https://example.com/book.pdf",
            totalPages: 96,
            thumbnailData: UIImage(systemName: "book")?.pngData()
        ),
        user: UserEntity(
            id: "user1",
            email: "child@example.com",
            name: "Alice",
            role: .child,
            totalPoints: 50
        ),
        onBookClicked: {}
    )
}

#Preview("Child - Not Started") {
    BookItemView(
        book: BookEntity(
            id: "2",
            title: "Alice in Wonderland",
            role: "child",
            pdfURL: "https://example.com/alice.pdf",
            totalPages: 120,
            thumbnailData: UIImage(systemName: "book.closed")?.pngData()
        ),
        user: UserEntity(
            id: "user2",
            email: "child2@example.com",
            name: "Bob",
            role: .child,
            totalPoints: 0
        ),
        onBookClicked: {}
    )
}
