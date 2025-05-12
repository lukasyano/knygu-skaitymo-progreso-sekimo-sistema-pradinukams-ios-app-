import Lottie
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

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            ZStack(alignment: .bottom) {
                if let bookURL = book.fileURL {
                    PDFDocumentView(
                        url: bookURL) { [weak interactor] in interactor?.onBookPageChanged($0) }

                    HoldToDismissButton(action: dismiss.callAsFunction)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 30)
                }
            }
            .onChange(of: viewModel.shouldCelebrate) { _, shouldCelebrate in
                guard shouldCelebrate else { return }

                // Play effects
                HapticManager.playSuccessVibration()
                SoundPlayer.shared.playCelebrationSound()

                // Reset after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    viewModel.shouldCelebrate = false
                }
            }
        }
        .sensoryFeedback(.success, trigger: viewModel.shouldCelebrate)
        .onAppear { [weak interactor] in interactor?.viewDidAppear() }
        .animation(.easeInOut, value: viewModel.isLoading)
        .overlay(alignment: .top) {
            if viewModel.shouldCelebrate {
                ZStack {
                    Color.clear
                    LottieView(animation: .named(lottieList.randomElement() ?? "star.json")).looping()
                        .animationSpeed(0.9)
                        .frame(height: 200, alignment: .top)
                }
                .allowsHitTesting(false)
            }
        }
        .animation(.spring, value: viewModel.shouldCelebrate)
    }
}

import UIKit

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
}
