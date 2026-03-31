import Foundation
import AVFoundation

final class AudioManager: ObservableObject {
    private var players: [AVAudioPlayer] = []
    private var soundURLs: [URL] = []

    @Published var volume: Float = 1.0
    @Published var isEnabled = true

    var soundCount: Int { soundURLs.count }

    init() {
        loadSounds()
    }

    private func loadSounds() {
        let extensions = ["mp3", "wav", "aiff", "m4a"]

        for ext in extensions {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                soundURLs.append(contentsOf: urls)
            }
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: "Resources") {
                soundURLs.append(contentsOf: urls)
            }
        }

        for url in soundURLs {
            if let player = try? AVAudioPlayer(contentsOf: url) {
                player.prepareToPlay()
                players.append(player)
            }
        }
    }

    func playRandomSound() {
        guard isEnabled, !players.isEmpty else { return }
        let index = Int.random(in: 0..<players.count)
        players[index].volume = max(0.0, min(1.0, volume))
        players[index].currentTime = 0
        players[index].play()
    }
}
