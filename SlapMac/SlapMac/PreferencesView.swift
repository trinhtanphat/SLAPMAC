import SwiftUI

struct PreferencesView: View {
    @State private var sensitivity: Double = 1.5
    @State private var volume: Double = 1.0
    @State private var cooldown: Double = 0.3
    @State private var launchAtLogin: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SlapMac Preferences")
                .font(.title)
                .fontWeight(.bold)
            
            Divider()
            
            // Sensitivity
            VStack(alignment: .leading, spacing: 8) {
                Text("Detection Sensitivity")
                    .font(.headline)
                HStack {
                    Text("Light")
                        .foregroundColor(.secondary)
                    Slider(value: $sensitivity, in: 0.5...5.0, step: 0.1)
                    Text("Hard")
                        .foregroundColor(.secondary)
                }
                Text("Current: \(String(format: "%.1f", sensitivity))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Volume
            VStack(alignment: .leading, spacing: 8) {
                Text("Volume")
                    .font(.headline)
                HStack {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary)
                    Slider(value: $volume, in: 0.0...1.0, step: 0.05)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary)
                }
                Text("\(Int(volume * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Cooldown
            VStack(alignment: .leading, spacing: 8) {
                Text("Cooldown (seconds between sounds)")
                    .font(.headline)
                HStack {
                    Text("0.1s")
                        .foregroundColor(.secondary)
                    Slider(value: $cooldown, in: 0.1...2.0, step: 0.1)
                    Text("2.0s")
                        .foregroundColor(.secondary)
                }
                Text("\(String(format: "%.1f", cooldown))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Launch at login
            Toggle("Launch at Login", isOn: $launchAtLogin)
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Reset to Defaults") {
                    sensitivity = 1.5
                    volume = 1.0
                    cooldown = 0.3
                    launchAtLogin = false
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 420, height: 450)
    }
}

#Preview {
    PreferencesView()
}
