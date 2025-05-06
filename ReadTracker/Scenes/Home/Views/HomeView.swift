import SwiftUI

private enum ViewConstants {}

struct HomeView<ViewModel: HomeViewModel>: View {
    // MARK: - Variables
    private unowned var interactor: HomeInteractor
    @ObservedObject private var viewModel: ViewModel

    // MARK: - Init
    init(
        interactor: HomeInteractor,
        viewModel: ViewModel
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

//            if viewModel.books.isEmpty {
//                LoadingView()
//            } else {
                contentView
                    .navigationTitle(viewModel.title)
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(
                                action: { [weak interactor] in interactor?.onLogOutTap() },
                                label: { Text("Atsijungti") }
                            )
                        }
                    }
           // 
        }
        .animation(.bouncy, value: viewModel.isLoading)
        .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })
//        .onDisappear { [weak interactor] in interactor?.viewDidChange(.onDisappear) }
    }

    @ViewBuilder
    private var contentView: some View {
        booksGridView()
    }

    private func chipView(for book: HomeModels.BooksPresentable) -> some View {
        var isStartedReading: Bool {
            guard let readedPages = book.readedPages else { return false }
            return readedPages > 0
        }

        return HStack {
            Spacer()
            Text(isStartedReading ? "Skaitoma" : "Nepradėta")
                .padding(.vertical, 1)
                .padding(.horizontal, 12)
                .background(isStartedReading ? Color.green.gradient : Color.gray.gradient)
                .clipShape(Capsule())
        }
    }

    private func booksGridView() -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]

        return ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.books) { book in
                    VStack(spacing: 8) {
                        chipView(for: book)

                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.brown.gradient.opacity(0.5))
                                .frame(width: 150, height: 200)

                            if let image = book.image {
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

                        Text(book.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity)

                        Spacer()

                        if let totalPages = book.totalPages {
                            let readedPages = book.readedPages ?? 0
                            HStack {
                                Spacer()
                                Text("\(readedPages) / \(totalPages) psl.")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brown.gradient.opacity(0.5))
                    .cornerRadius(16)
                    .shadow(color: .white, radius: 2)
                    .onTapGesture { [weak interactor] in interactor?.onBookClicked(book.id) }
                }
            }
            .padding()
        }
    }
}

#if DEBUG
    import SwiftUI

    struct HomeView_Previews: PreviewProvider {
        class MockHomeInteractor: HomeInteractor {
            func onBookClicked(_ bookID: String) {}
            func onLogOutTap() {}
            static let mockInstance = MockHomeInteractor()
            func viewDidAppear() {}
            func tapConfirm() {}
        }

        struct PreviewContainer: View {
            @StateObject private var viewModel = DefaultHomeViewModel()

            var body: some View {
                NavigationView {
                    HomeView(
                        interactor: MockHomeInteractor.mockInstance,
                        viewModel: viewModel
                    )
                }
                .onAppear {
                    viewModel.displayBooks(
                        (0 ..< 30).map {
                            .init(
                                id: "book_\($0)",
                                title: "Knyga \($0)",
                                readedPages: 10,
                                totalPages: 20,
                                image:
                                UIImage(systemName: "book")
                                    ?? .init()
                            )
                        }
                    )
                }
            }
        }

        static var previews: some View {
            PreviewContainer()
        }
    }

#endif
