import Combine
import Resolver
import SwiftData
import SwiftUI

struct HomeView<ViewModel: HomeViewModel>: View {
    // MARK: - Variables
    @State private var showLogoutConfirmation: Bool = false
    private unowned var interactor: HomeInteractor
    @ObservedObject private var viewModel: ViewModel
    let userID: String

    @State private var isMusicOn: Bool = false

    @Query private var books: [BookEntity]
    @Query private var users: [UserEntity]

    @StateObject private var soundPlayer = DefaultSoundPlayer()

    init(
        interactor: HomeInteractor,
        viewModel: ViewModel,
        userID: String
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
        self.userID = userID

        _users = Query(
            filter: #Predicate<UserEntity> { $0.id == userID },
            sort: \.name
        )
    }

    var currentUser: UserEntity? {
        // Debug print to console
        if let user = users.first {
            print("User found with id: \(user.id)")
        } else {
            print("No user found for userID: \(userID)")
        }
        return users.first
    }

    private var filteredBooks: [BookEntity] {
        guard let currentUser = currentUser else {
            print("filteredBooks: currentUser is nil")
            return []
        }
        let matchedBooks = books.filter { book in
            book.role == currentUser.role.rawValue
        }
        print("filteredBooks: Found \(matchedBooks.count) books for role: \(currentUser.role.rawValue)")
        return matchedBooks
    }

    private func handleMusicControl() {
        if isMusicOn {
            soundPlayer.playLobbySound()
        } else {
            soundPlayer.stopPlayer()
        }
    }

    private var musicControlOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button(action: {
                    isMusicOn.toggle()
                    handleMusicControl()
                }) {
                    Image(systemName: isMusicOn ? "pause.circle.fill" : "play.circle.fill")
                        .resizable()
                        .frame(width: 60, height: 60)
                        .foregroundColor(isMusicOn ? .blue : .gray)
                        .shadow(radius: 4)
                        .padding()
                }
            }
        }
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

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            if books.isEmpty {
                LoadingView()
            } else {
                mainContentView
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing, content: logoutButton)
                        ToolbarItem(placement: .topBarLeading, content: profileButton)
                    }
                    .animation(.easeInOut, value: books.isEmpty)
                    .animation(.bouncy, value: filteredBooks)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .toolbarBackground(Constants.mainScreenColor, for: .navigationBar)
                    .onAppear(perform: { [weak interactor] in interactor?.viewDidAppear() })
                    // .onAppear(perform: soundPlayer.playLobbySound)
                    .onDisappear(perform: soundPlayer.stopPlayer)
            }

            musicControlOverlay
        }
    }

    private var notStartedSectionTitle: some View {
        Group {
            if let currentUser {
                if currentUser.role == .child {
                    Text("Nepradėtos")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, startedBooks.isEmpty ? 0 : 24)
                } else {
                    Text("Jums rekomanduojamos")
                        .font(.headline)
                        .padding(.horizontal)
                        .padding(.top, startedBooks.isEmpty ? 0 : 24)
                }
            }
        }
    }

    @ViewBuilder
    private var mainContentView: some View {
        if let currentUser {
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 8) {
                    if !startedBooks.isEmpty {
                        Text("Skaitomos")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(startedBooks) { book in
                            BookItemView(
                                book: book,
                                user: currentUser,
                                onBookClicked: { [weak interactor] in
                                    interactor?.onBookClicked(book, with: currentUser)
                                }
                            )
                        }
                    }

                    if !notStartedBooks.isEmpty {
                        notStartedSectionTitle

                        ForEach(notStartedBooks) { book in
                            BookItemView(
                                book: book,
                                user: currentUser,
                                onBookClicked: { [weak interactor] in
                                    interactor?.onBookClicked(book, with: currentUser)
                                }
                            )
                        }
                    }

                    Text("Tavo bibliotekoje yra: \(filteredBooks.count) knygų (-os)")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.footnote)
                        .padding(.top, 24)
                        .padding(.horizontal)
                }
                .padding(.top)
            }
        }
    }

    private var startedBooks: [BookEntity] {
        if let currentUser {
            filteredBooks
                .filter { book in
                    currentUser.progressData.first(where: { $0.bookId == book.id })?.pagesRead ?? 0 > 0
                }
                .sorted { lhs, rhs in
                    let lhsProgress = currentUser.progressData.first { $0.bookId == lhs.id }
                    let rhsProgress = currentUser.progressData.first { $0.bookId == rhs.id }

                    let lhsRatio = lhsProgress.map { Double($0.pagesRead) / Double(max($0.totalPages, 1)) } ?? 0
                    let rhsRatio = rhsProgress.map { Double($0.pagesRead) / Double(max($0.totalPages, 1)) } ?? 0

                    return lhsRatio > rhsRatio
                }
        } else { [] }
    }

    private var notStartedBooks: [BookEntity] {
        if let currentUser {
            filteredBooks
                .filter { book in
                    (currentUser.progressData.first(where: { $0.bookId == book.id })?.pagesRead ?? 0) == 0
                }
        } else { [] }
    }

    private var sortedBooksByProgress: [BookEntity] {
        if let currentUser {
            filteredBooks.sorted { first, second in
                let firstProgress = currentUser.progressData.first { $0.bookId == first.id }
                let secondProgress = currentUser.progressData.first { $0.bookId == second.id }

                let firstRatio = firstProgress.map { Double($0.pagesRead) / Double(max($0.totalPages, 1)) } ?? 0
                let secondRatio = secondProgress.map { Double($0.pagesRead) / Double(max($0.totalPages, 1)) } ?? 0

                return firstRatio > secondRatio
            }
        } else { [] }
    }
}

private func chipView(pagesRead: Int) -> some View {
    let isStartedReading = pagesRead > 0

    return Text(isStartedReading ? "Skaitoma" : "Nepradėta")
        .frame(maxWidth: .infinity)
        .padding(.vertical, 1)
        .background(isStartedReading ? Color.mint.gradient.opacity(0.7) : Color.gray.gradient.opacity(0.7))
        .clipShape(Capsule())
}
