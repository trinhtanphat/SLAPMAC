import SwiftUI

struct ContentView: View {
    @ObservedObject var detector: SlapDetector
    @ObservedObject var audio: AudioManager
    @Binding var slapCount: Int
    @State private var selectedTab = 0

    private let bgColor = Color(red: 0.086, green: 0.086, blue: 0.149)
    private let accentRed = Color(red: 0.91, green: 0.27, blue: 0.38)

    var body: some View {
        TabView(selection: $selectedTab) {
            homeView
                .tabItem { Label("Home", systemImage: "hand.raised.fill") }
                .tag(0)

            SettingsView(detector: detector, audio: audio)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(1)

            DonateView()
                .tabItem { Label("Donate", systemImage: "heart.fill") }
                .tag(2)
        }
        .tint(accentRed)
        .preferredColorScheme(.dark)
    }

    private var homeView: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer().frame(height: 20)

                Text("🖐 SlapMac")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(accentRed)

                Text("Slap your phone, hear funny sounds!")
                    .font(.subheadline)
                    .foregroundColor(.gray)

                Spacer()

                Text("\(slapCount)")
                    .font(.system(size: 96, weight: .bold, design: .monospaced))
                    .foregroundColor(accentRed)
                    .contentTransition(.numericText())
                    .animation(.spring, value: slapCount)

                Text("SLAPS")
                    .font(.title3)
                    .foregroundColor(.white)
                    .tracking(4)

                Spacer()

                Button {
                    if detector.isRunning {
                        detector.stop()
                    } else {
                        detector.start()
                    }
                } label: {
                    HStack {
                        Image(systemName: detector.isRunning ? "pause.fill" : "play.fill")
                        Text(detector.isRunning ? "Pause" : "Resume")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(detector.isRunning ? accentRed : Color.green)
                    .cornerRadius(25)
                }

                Button("🔊 Test Sound") {
                    audio.playRandomSound()
                    slapCount += 1
                }
                .font(.subheadline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .cornerRadius(20)

                Text("\(audio.soundCount) sound(s) loaded")
                    .font(.caption)
                    .foregroundColor(.gray)

                if !detector.isAvailable {
                    Text("⚠️ Accelerometer not available (Simulator?)")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }

                Spacer().frame(height: 20)
            }
            .padding()
        }
    }
}
