import SwiftUI
import AVFoundation

@main
struct SlapMacApp: App {
    @StateObject private var detector = SlapDetector()
    @StateObject private var audio = AudioManager()
    @State private var slapCount = 0

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(detector: detector, audio: audio, slapCount: $slapCount)
                .onAppear {
                    detector.onSlapDetected = {
                        audio.playRandomSound()
                        slapCount += 1
                    }
                    detector.start()
                }
        }
    }
}
