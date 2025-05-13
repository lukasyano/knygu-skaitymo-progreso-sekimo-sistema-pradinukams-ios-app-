import AVFoundation
import Foundation
import UIKit

protocol SoundPlayer {
    func playCelebrationSound()
    func playLobbySound()
    func playPageFlipSound()
    func stopPlayer()
}

final class DefaultSoundPlayer: SoundPlayer, ObservableObject {
    private var player: AVAudioPlayer?
    
    func playPageFlipSound() {
        DispatchQueue.main.async {
            guard let url = Bundle.main.url(forResource: "page-flip", withExtension: "mp3") else { return }
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
            self.player = try? AVAudioPlayer(contentsOf: url)
            self.player?.play()
        }
    }

    func playCelebrationSound() {
        DispatchQueue.main.async {
            guard let url = Bundle.main.url(forResource: "checkpoint", withExtension: "mp3") else { return }
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
            self.player = try? AVAudioPlayer(contentsOf: url)
            self.player?.play()
        }
    }

    func playLobbySound() {
        DispatchQueue.main.async {
            guard let url = Bundle.main.url(forResource: "lobby", withExtension: "mp3") else { return }
            try? AVAudioSession.sharedInstance().setCategory(.ambient)
            self.player = try? AVAudioPlayer(contentsOf: url)
            self.player?.play()
        }
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
