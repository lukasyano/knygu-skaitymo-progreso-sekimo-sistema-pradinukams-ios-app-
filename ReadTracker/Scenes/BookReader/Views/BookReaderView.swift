import Combine
import Lottie
import PDFKit
import Resolver
import SwiftUI

struct BookReaderView<ViewModel: BookReaderViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    @State private var lastPageChangeTime = Date().addingTimeInterval(-5)
    @State private var cooldownProgress: CGFloat = 0.0
    @State private var isCooldownActive = false

    @Injected private var userRepository: UserRepository

    private let book: BookEntity
    private let user: UserEntity

    private unowned var interactor: BookReaderInteractor
    @ObservedObject private var viewModel: ViewModel

    let lottieList = [
        "complete.json", "eye.json", "reading.json", "star.json"
    ]

    @State private var currentPage: Int
    @State private var isOnLastPage = false

    private let soundPlayer: SoundPlayer = DefaultSoundPlayer()

    init(
        interactor: BookReaderInteractor,
        viewModel: ViewModel,
        book: BookEntity,
        user: UserEntity
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
        self.book = book
        self.user = user

        _currentPage = State(initialValue: user.progressData.first { $0.bookId == book.id }?.pagesRead ?? 0)
    }

    @State private var totalPages = 1

    var progress: Double {
        return totalPages > 0 ? Double(currentPage + 1) / Double(totalPages) : 0
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            VStack {
                topNavigation
                pdfContent

                if user.role == .child {
                    bottomNavigation
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    startNewSession()
                }
            }
            .background(Color(.systemBackground))
            .onAppear {
                //  interactor.startNewSession()
                updateTotalPages()
            }

            .onChange(of: viewModel.shouldCelebrate) { _, shouldCelebrate in
                guard shouldCelebrate else { return }
                playCelebrationEffect()
            }
            .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                guard user.role != .parent else {
                    isCooldownActive = false
                    return
                }
                let elapsed = Date().timeIntervalSince(lastPageChangeTime)
                isCooldownActive = elapsed < 5
                cooldownProgress = max(0, 1.0 - (elapsed / 5))
            }
        }
        .overlay(celebrationOverlay)
        .animation(.spring(), value: viewModel.shouldCelebrate)
    }

    func clearCurrentSession() {
        currentSession = nil
        currentPages.removeAll()
        print("[Session] Session cleared")
    }

    private func stopReading() {
//        interactor.saveSessionDurationFromCurrentSession()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            dismiss.callAsFunction()
//        }
    }

    @State private var cancelBag = Set<AnyCancellable>()
    @State private var currentSession: ReadingSession?
    @State private var currentPages: [PageRead] = []

    // MARK: - Top Navigation
    private var topNavigation: some View {
        HStack {
            Button(action: {
                if let currentSession {
                    let duration = Date().timeIntervalSince(currentSession.startTime)

                    saveSession(currentSession, duration: duration)
                }
            }) {
                Image(systemName: "xmark")
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.2)))
                    .padding(.leading, 12)
            }
            Spacer()

            VStack {
                Text(book.title)
                    .font(.title2)
                Text("Puslapis \(currentPage + 1) iš \(totalPages)")
                    .font(.headline)
            }
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                    .frame(width: 40, height: 40)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.blue, lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Text("\(Int(progress * 100))%")
                    .font(.caption)
            }
            .padding()
        }
        .background(Color.white)
        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    // MARK: - PDF Content
    private var pdfContent: some View {
        ZStack {
            if let bookURL = book.fileURL {
                StablePDFDocumentView(
                    url: book.fileURL!,
                    initialPageIndex: currentPage,
                    isOnLastPage: $isOnLastPage,
                    onPageChange: { newPage in
                        currentPage = newPage
                        // Save progress here
                    },
                    role: user.role
                )
                .id("pdf_\(book.id)")
            } else {
                Text("Unable to load PDF")
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }

    private var cooldownOverlay: some View {
        Group {
            if user.role != .parent && isCooldownActive {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: cooldownProgress)
                        .stroke(Color.blue, lineWidth: 3)
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 44, height: 44)
            }
        }
    }

    private func markAsRead() {
        if user.role != .parent {
            interactor.onBookPageChanged(totalPages)
        }
        stopReading()
    }

    func startNewSession() {
        guard currentSession == nil else {
            print("[Session] Session already exists")
            return
        }

        currentSession = ReadingSession(
            bookId: book.id,
            startTime: Date(),
            endTime: Date(),
            duration: 0,
            pagesRead: []
        )
        print("[Session] New session started: \(currentSession!.startTime)")
    }

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack {
            Button(action: goToPreviousPage) {
                Image(systemName: "chevron.left")
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.7)))
                    .foregroundColor(.white)
            }
            .disabled(currentPage == 0 || (user.role != .parent && isCooldownActive))
            .overlay(cooldownOverlay)

            Spacer()

            if isOnLastPage {
//                Button(action: markAsRead) {
                Button("Perskaičiau") {
                    markAsRead()
                }
                .warmButtonStyle()
                .padding()

            } else {
                Text("Page \(currentPage + 1) of \(totalPages)")
                    .font(.headline)
            }

            Spacer()

            Button(action: goToNextPage) {
                Image(systemName: "chevron.right")
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.7)))
                    .foregroundColor(.white)
            }
            .disabled(currentPage == totalPages - 1 || (user.role != .parent && isCooldownActive))
            .overlay(cooldownOverlay)
        }
        .padding()
        .background(Color.white)
        .shadow(color: .gray.opacity(0.3), radius: 4, x: 0, y: -2)
    }

    // MARK: - Celebration Overlay
    private var celebrationOverlay: some View {
        ZStack {
            if viewModel.shouldCelebrate {
                LottieView(animation: .named("complete.json"))
                    .looping()
                    .animationSpeed(0.9)
                    .frame(height: 200)
                    .allowsHitTesting(false)
            }
        }
        .transition(.opacity)
    }

    // MARK: - Navigation Logic
    private func goToPreviousPage() {
        guard currentPage > 0 else { return }
        currentPage -= 1
        if user.role != .parent {
            lastPageChangeTime = Date()
            interactor.onBookPageChanged(currentPage)
        }
    }

    private func goToNextPage() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
        if user.role != .parent {
            lastPageChangeTime = Date()
            interactor.onBookPageChanged(currentPage)
        }
    }

    private func updateTotalPages() {
        guard let url = book.fileURL, let document = PDFDocument(url: url) else { return }
        totalPages = document.pageCount
    }

    // MARK: - Celebration Effect
    private func playCelebrationEffect() {
        HapticManager.playSuccessVibration()
        soundPlayer.playCelebrationSound()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            viewModel.shouldCelebrate = false
        }
    }

    @MainActor // ← guarantees all state writes are on the main thread
    private func saveSession(
        _ session: ReadingSession,
        duration: TimeInterval
    ) {
        // 1. Prepare the value you want to persist
        var sessionToSave = session
        sessionToSave.endTime = Date()
        sessionToSave.duration = duration
        sessionToSave.pagesRead = .init(repeating: .init(pageNumber: 1, timestamp: .init()), count: 2)

        // 2. Fire-and-forget Combine pipeline
        userRepository
            .saveReadingSession(sessionToSave, for: user.id)
            .receive(on: DispatchQueue.main) // UI updates → main queue
            .sink { [self] completion in // weak to break retain-cycle
                switch completion {
                case .finished:
                    print("[Session] Saved \(sessionToSave.pagesRead.count) pages")
                    self.clearCurrentSession()
                    dismiss.callAsFunction() // ← safe: `self` is a class on main thread
                case let .failure(error):
                    print("[Session] Save failed – keeping session for retry: \(error)")
                    self.currentSession = sessionToSave // keep a copy for retry
                    self.currentPages = sessionToSave.pagesRead
                }
            } receiveValue: { _ in }
            .store(in: &cancelBag)
    }
}
