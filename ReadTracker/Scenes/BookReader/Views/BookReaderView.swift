import SwiftUI
import Lottie

struct BookReaderView<ViewModel: BookReaderViewModel>: View {
    // MARK: - Variables
    @Environment(\.dismiss) private var dismiss
    let url: URL

    private unowned var interactor: BookReaderInteractor
    @ObservedObject private var viewModel: ViewModel

    init(
        interactor: BookReaderInteractor,
        viewModel: ViewModel,
        url: URL
    ) {
        self.interactor = interactor
        self.viewModel = viewModel
        self.url = url
    }

    var body: some View {
        ZStack {
            Constants.mainScreenColor.ignoresSafeArea()

            ZStack(alignment: .bottom) {
                PDFDocumentView(
                    url: url) { [weak interactor] in interactor?.onBookPageChanged($0) }

                HoldToDismissButton(action: dismiss.callAsFunction)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 30)

                if viewModel.shouldCelebrate {
                    ZStack {
                        Color.clear
                        LottieView(animation: .named("star.json")).looping()
                            .animationSpeed(0.9)
                            .frame(height: 600)
                        
                    }
                    .allowsHitTesting(false)
                }
            }
            .onChange(of: viewModel.shouldCelebrate) { shouldCelebrate in
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
    }
}

import UIKit

struct HapticManager {
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
