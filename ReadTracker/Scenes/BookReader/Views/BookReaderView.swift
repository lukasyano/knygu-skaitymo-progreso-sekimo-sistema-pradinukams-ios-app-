import Lottie
import PDFKit
import SwiftUI

struct BookReaderView<ViewModel: BookReaderViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    private let book: BookEntity
    private let user: UserEntity

    private unowned var interactor: BookReaderInteractor
    @ObservedObject private var viewModel: ViewModel

    let lottieList = [
        "complete.json", "eye.json", "reading.json", "star.json"
    ]

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
    }

    @State private var currentPage = 0
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
                updateTotalPages()
            }
            .onChange(of: viewModel.shouldCelebrate) { _, shouldCelebrate in
                guard shouldCelebrate else { return }
                playCelebrationEffect()
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
            }
            Spacer()

            Text("Page \(currentPage + 1) of \(totalPages)")
                .font(.headline)

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
                PDFDocumentView(
                    url: bookURL,
                    onPageChange: { pageIndex in
                        currentPage = pageIndex
                    }
                )
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

    // MARK: - Bottom Navigation
    private var bottomNavigation: some View {
        HStack {
            Button(action: goToPreviousPage) {
                Image(systemName: "chevron.left")
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.7)))
                    .foregroundColor(.white)
            }
            .disabled(currentPage == 0)

            Spacer()

            Text("Page \(currentPage + 1) of \(totalPages)")
                .font(.headline)

            Spacer()

            Button(action: goToNextPage) {
                Image(systemName: "chevron.right")
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.7)))
                    .foregroundColor(.white)
            }
            .disabled(currentPage == totalPages - 1)
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
    }

    private func goToNextPage() {
        guard currentPage < totalPages - 1 else { return }
        currentPage += 1
    }

    private func updateTotalPages() {
        guard let url = book.fileURL, let document = PDFDocument(url: url) else { return }
        totalPages = document.pageCount
    }

    // MARK: - Celebration Effect
    private func playCelebrationEffect() {
        HapticManager.playSuccessVibration()
        SoundPlayer.shared.playCelebrationSound()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            viewModel.shouldCelebrate = false
        }
    }
}

enum HapticManager {
    static func playSuccessVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

import AVFoundation

class SoundPlayer {
    static let shared = SoundPlayer()
    private var player: AVAudioPlayer?

    func playCelebrationSound() {
        guard let url = Bundle.main.url(forResource: "checkpoint", withExtension: "mp3") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func playLobbySound() {
        guard let url = Bundle.main.url(forResource: "lobby", withExtension: "mp3") else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func stopLobbySound() {
        player?.stop()
    }
}
