import SwiftUI
import Combine
import Resolver

private enum ViewConstants {}

struct HomeView<ViewModel: HomeViewModel>: View {
    // MARK: - Variables
    @State private var showLogoutConfirmation: Bool = false
    private unowned var interactor: HomeInteractor
    @ObservedObject private var viewModel: ViewModel
    private let userRepository: UserRepository

    // MARK: - Init
    init(
        interactor: HomeInteractor,
        viewModel: ViewModel,
        userRepository: UserRepository = Resolver.resolve()
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
        self.userRepository = userRepository
    }

    func profileButton() -> some View {
        Button(
            action: { [weak interactor] in interactor?.onProfileTap() },
            label: {
                HStack {
                    Text("Tavo Profilis").frame(width: 120)
                    Image(systemName: "person.crop.circle.fill")
                }
            }
        )
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .tint(.black)
    }

    func logoutButton() -> some View {
        Button(
            action: { showLogoutConfirmation.toggle() },
            label: {
                HStack {
                    Text("Atsijungti").frame(width: 120)
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
        )
        .buttonStyle(.bordered)
        .buttonBorderShape(.roundedRectangle)
        .tint(.black)
        .alert("Atsijungti", isPresented: $showLogoutConfirmation) {
            Button("Atšaukti", role: .cancel) {}
            Button("Atsijungti", role: .destructive) {
                interactor.onLogOutTap()
            }
        } message: {
            Text("Ar tikrai norite atsijungti?")
        }
    }

    @ViewBuilder
    func contentView() -> some View {
        ScrollView {
            LazyVStack(spacing: 16, pinnedViews: .sectionFooters) {
                Section {
                    booksGridView()
                } footer: {
                    Text(viewModel.title).font(.footnote)
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            contentView()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading, content: logoutButton)
                    ToolbarItem(placement: .topBarTrailing, content: profileButton)
                }
                .animation(.bouncy, value: viewModel.isLoading)
                .animation(.bouncy, value: viewModel.books)
                .toolbarBackground(Constants.mainScreenColor, for: .navigationBar)
                .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })

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
                    // Get progress for this book
                    let bookProgress = viewModel.progressData.first { $0.bookId == book.id }
                    let pagesRead = bookProgress?.pagesRead ?? 0
                    let totalPages = bookProgress?.totalPages ?? book.totalPages ?? 0

                    VStack(spacing: 8) {
                        if viewModel.user.role == .child {
                            chipView(pagesRead: pagesRead)  // Updated chip view
                        }

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

                        // Updated progress display
                        if totalPages > 0 {
                            HStack {
                                Spacer()
                                Text("\(pagesRead)/\(totalPages) psl.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(Color.clear.opacity(0.5))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.brown.opacity(0.8), lineWidth: 2)
                    )
                    .onTapGesture { [weak interactor] in interactor?.onBookClicked(book.id) }
                }
            }
            .padding()
        }
    }

    // Updated chip view that uses progress data
    private func chipView(pagesRead: Int) -> some View {
        let isStartedReading = pagesRead > 0
        
        return Text(isStartedReading ? "Skaitoma" : "Nepradėta")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 1)
            .background(isStartedReading ? Color.green.gradient : Color.gray.gradient)
            .clipShape(Capsule())
    }
}
