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

    @State private var sessionStartTime: Date?

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
                bottomNavigation
            }
            .background(Color(.systemBackground))
            .onAppear {
                sessionStartTime = Date()
                updateTotalPages()
            }
            .onDisappear {
                guard let start = sessionStartTime else { return }
                let duration = Date().timeIntervalSince(start)
                interactor.saveSessionDuration(duration)
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

    // MARK: - Top Navigation
    private var topNavigation: some View {
        HStack {
            Button(action: dismiss.callAsFunction) {
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
                    }
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
            interactor.onBookPageChanged(totalPages - 1)
        }
        dismiss()
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
                Button(action: markAsRead) {
                    Text("Mark as Read")
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(user.role != .parent && isCooldownActive)
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
                LottieView(animation: .named(lottieList.randomElement() ?? "star.json"))
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
}
