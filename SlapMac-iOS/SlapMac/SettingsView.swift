import SwiftUI

struct SettingsView: View {
    @ObservedObject var detector: SlapDetector
    @ObservedObject var audio: AudioManager

    @State private var sensitivity: Double = 1.5
    @State private var volume: Double = 1.0
    @State private var cooldown: Double = 1.5

    private let bgColor = Color(red: 0.086, green: 0.086, blue: 0.149)
    private let accentRed = Color(red: 0.91, green: 0.27, blue: 0.38)

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("⚙️ Settings")
                        .font(.title.bold())
                        .foregroundColor(accentRed)
                        .frame(maxWidth: .infinity, alignment: .center)

                    // Sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sensitivity: \(String(format: "%.1f", sensitivity))")
                            .foregroundColor(.white)
                        Slider(value: $sensitivity, in: 0.5...4.0, step: 0.1)
                            .tint(accentRed)
                            .onChange(of: sensitivity) {
                                detector.sensitivity = sensitivity
                            }
                    }

                    // Volume
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Volume: \(Int(volume * 100))%")
                            .foregroundColor(.white)
                        Slider(value: $volume, in: 0...1, step: 0.01)
                            .tint(accentRed)
                            .onChange(of: volume) {
                                audio.volume = Float(volume)
                            }
                    }

                    // Cooldown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cooldown: \(Int(cooldown * 1000))ms")
                            .foregroundColor(.white)
                        Slider(value: $cooldown, in: 0.5...5.0, step: 0.1)
                            .tint(accentRed)
                            .onChange(of: cooldown) {
                                detector.cooldownInterval = cooldown
                            }
                    }

                    // Reset
                    Button("Reset to Defaults") {
                        sensitivity = 1.5
                        volume = 1.0
                        cooldown = 1.5
                        detector.sensitivity = 1.5
                        detector.cooldownInterval = 1.5
                        audio.volume = 1.0
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding()
            }
        }
        .onAppear {
            sensitivity = detector.sensitivity
            volume = Double(audio.volume)
            cooldown = detector.cooldownInterval
        }
    }
}
