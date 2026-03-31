import SwiftUI

struct PreferencesView: View {
    @State private var sensitivity: Double = UserDefaults.standard.double(forKey: "sensitivity") == 0 ? 1.5 : UserDefaults.standard.double(forKey: "sensitivity")
    @State private var volume: Double = UserDefaults.standard.double(forKey: "volume") == 0 ? 1.0 : UserDefaults.standard.double(forKey: "volume")
    @State private var cooldown: Double = UserDefaults.standard.double(forKey: "cooldown") == 0 ? 1.5 : UserDefaults.standard.double(forKey: "cooldown")
    @State private var launchAtLogin: Bool = UserDefaults.standard.bool(forKey: "launchAtLogin")
    
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
                    cooldown = 1.5
                    launchAtLogin = false
                    savePreferences()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(24)
        .frame(width: 420, height: 450)
        .onChange(of: sensitivity) { _ in savePreferences() }
        .onChange(of: volume) { _ in savePreferences() }
        .onChange(of: cooldown) { _ in savePreferences() }
        .onChange(of: launchAtLogin) { _ in savePreferences() }
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(sensitivity, forKey: "sensitivity")
        UserDefaults.standard.set(volume, forKey: "volume")
        UserDefaults.standard.set(cooldown, forKey: "cooldown")
        UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        NotificationCenter.default.post(name: NSNotification.Name("PreferencesChanged"), object: nil)
    }
}

#Preview {
    PreferencesView()
}
