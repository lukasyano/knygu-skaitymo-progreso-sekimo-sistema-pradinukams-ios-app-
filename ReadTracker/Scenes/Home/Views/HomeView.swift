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

            if viewModel.isLoading {
                LoadingView()
            } else {
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
            }
        }
        .animation(.bouncy, value: viewModel.isLoading)
        .onFirstAppear(perform: { [weak interactor] in interactor?.viewDidChange(.onAppear) }, resetOnDisappear: false)
        .onDisappear { [weak interactor] in interactor?.viewDidChange(.onDisappear) }
    }

    @ViewBuilder
    private var contentView: some View {
        booksGridView()
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
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(UIColor.secondarySystemBackground))
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
                            .padding(.horizontal, 4)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
            func viewDidChange(_ type: ViewDidChangeType) {}
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
