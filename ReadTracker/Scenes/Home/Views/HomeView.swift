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

    @State private var todayMinutesRead = 0
    @State private var cancellables = Set<AnyCancellable>()

    @State private var isMusicOn: Bool = false
    @State private var readingSessions: [ReadingSession]?

    @Injected private var userRepository: UserRepository

    @Query private var books: [BookEntity]
    @Query private var users: [UserEntity]

    @StateObject private var soundPlayer = DefaultSoundPlayer()

    @State private var sessionStartTime: Date?
    @State private var currentSessionDuration: TimeInterval = 0
    private let sessionTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(
        interactor: HomeInteractor,
        viewModel: ViewModel,
        userID: String
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
        self.userID = userID

        _users = Query(filter: #Predicate<UserEntity> { $0.id == userID })
    }

    var currentUser: UserEntity? {
        return users.first
    }

    private var filteredBooks: [BookEntity] {
        guard let currentUser = currentUser else {
            return []
        }
        return books.filter { book in
            book.role == currentUser.role.rawValue
        }
    }

    private func handleMusicControl() {
        if isMusicOn {
            soundPlayer.playLobbySound()
        } else {
            soundPlayer.stopPlayer()
        }
    }

    @StateObject var viewModel1 = ProgressStatsViewModel()

    private func loadTodayProgress() {
        viewModel1.loadStats(for: userID)

        todayMinutesRead = Int(viewModel1.stats.totalDuration)
        // TODO: - can be refactored
//        userRepository.getReadingSessions(userID: userID)
//            .map { sessions in
//                sessions.filter { session in
//                    Calendar.current.isDateInToday(session.startTime) || Calendar.current.isDateInToday(session.endTime)
//                }.reduce(0) { total, session in
//                    let startOfDay = Calendar.current.startOfDay(for: Date())
//                    let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
//
//                    let start = max(session.startTime, startOfDay)
//                    let end = min(session.endTime, endOfDay)
//
//                    let sessionDuration = max(0, end.timeIntervalSince(start))
//                    return total + Int(sessionDuration / 60)
//                }
//            }
//            .replaceError(with: 0)
//            .receive(on: DispatchQueue.main)
//            .sink { minutes in
//                todayMinutesRead = minutes
//            }
//            .store(in: &cancellables)
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
                    .onDisappear(perform: soundPlayer.stopPlayer)
                    .onAppear {
                        loadTodayProgress()
                    }
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
            VStack(spacing: 0) {
                if currentUser.role == .child, let dailyReadingGoal = currentUser.dailyReadingGoal {
                    DailyProgressBar(minutesRead: Int(viewModel1.stats.averageDailyDuration.asMinutes), goal: dailyReadingGoal)
                        .padding()
                        .frame(height: 45)
                        .zIndex(1)
                }

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

                        if !finishedBooks.isEmpty {
                            Text("Perskaityta")
                                .font(.headline)
                                .padding(.horizontal)
                                .padding(.top, 24)

                            ForEach(finishedBooks) { book in
                                BookItemView(
                                    book: book,
                                    user: currentUser,
                                    onBookClicked: { [weak interactor] in
                                        interactor?.onBookClicked(book, with: currentUser)
                                    }
                                )
                                .opacity(0.7)
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
    }

    private var startedBooks: [BookEntity] {
        if let currentUser {
            filteredBooks
                .filter { book in
                    if let progress = currentUser.progressData.first(where: { $0.bookId == book.id }) {
                        return progress.pagesRead > 0 && !progress.finished
                    }
                    return false
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
        guard let currentUser else { return [] }

        return filteredBooks
            .filter { book in
                !currentUser.progressData.contains { $0.bookId == book.id && $0.pagesRead > 0 }
            }
            .sorted { $0.title < $1.title }
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

    private var finishedBooks: [BookEntity] {
        guard let currentUser else { return [] }

        return filteredBooks.filter { book in
            currentUser.progressData.first {
                $0.bookId == book.id && $0.finished
            } != nil
        }.sorted { $0.title < $1.title }
    }
}
