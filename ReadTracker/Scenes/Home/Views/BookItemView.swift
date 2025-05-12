import SwiftUI

struct BookItemView<ViewModel: HomeViewModel>: View {
    let book: BookEntity
    let user: UserEntity
    let viewModel: ViewModel
    let interactor: HomeInteractor

//    private var progressData: ProgressData? {
//        viewModel.progressData.first { $0.bookId == book.id }
//    }

//    private var pagesRead: Int {
//        progressData?.pagesRead ?? 0
//    }
//
//    private var totalPages: Int {
//        progressData?.totalPages ?? book.totalPages ?? 0
//    }

    var body: some View {
        VStack(spacing: 8) {
            if user.role == .child {
              //  chipView
            }

            bookCoverImage
            bookTitle
          //  pagesReadIndicator
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color.clear.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.brown.opacity(0.8), lineWidth: 2)
        )
        .onTapGesture { [weak interactor] in interactor?.onBookClicked(book) }
    }

//    private var chipView: some View {
//        Text(pagesRead > 0 ? "Skaitoma" : "Nepradėta")
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 1)
//            .background(
//                pagesRead > 0
//                    ? Color.mint.gradient.opacity(0.7)
//                    : Color.gray.gradient.opacity(0.7)
//            )
//            .clipShape(Capsule())
//    }

    private var bookCoverImage: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.brown.gradient.opacity(0.5))
                .frame(width: 150, height: 200)

            if let data = book.thumbnailData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 200)
                    .clipped()
                    .cornerRadius(8)
            } else {
                ProgressView()
                    .frame(width: 150, height: 200)
            }
        }
    }

    private var bookTitle: some View {
        Text(book.title)
            .font(.headline)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .frame(maxWidth: .infinity)
    }

//    private var pagesReadIndicator: some View {
//        Group {
//            if totalPages > 0 {
//                HStack {
//                    Spacer()
//                    Text("\(pagesRead)/\(totalPages) psl.")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//    }
}
