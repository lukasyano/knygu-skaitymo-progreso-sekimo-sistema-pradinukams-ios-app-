import AVFoundation
import Foundation
import UIKit

protocol SoundPlayer {
    func playCelebrationSound()
    func playLobbySound()
    func stopPlayer()
}

final class DefaultSoundPlayer: SoundPlayer, ObservableObject {
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

    func stopPlayer() {
        player?.stop()
    }
}

enum HapticManager {
    static func playSuccessVibration() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}
