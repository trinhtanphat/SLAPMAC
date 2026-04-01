import SwiftUI
import AppKit

struct PreferencesView: View {
    @State private var sensitivity: Double = UserDefaults.standard.double(forKey: "sensitivity") == 0 ? 1.5 : UserDefaults.standard.double(forKey: "sensitivity")
    @State private var volume: Double = UserDefaults.standard.double(forKey: "volume") == 0 ? 1.0 : UserDefaults.standard.double(forKey: "volume")
    @State private var cooldown: Double = UserDefaults.standard.double(forKey: "cooldown") == 0 ? 1.5 : UserDefaults.standard.double(forKey: "cooldown")
    @State private var launchAtLogin: Bool = UserDefaults.standard.bool(forKey: "launchAtLogin")
    @State private var updateStatus: String = "Checking updates..."
    @State private var latestTag: String?
    @State private var isCheckingUpdate = false
    @AppStorage("languageCode") private var languageCode: String = "en"

    private let languages: [(String, String)] = [
        ("en", "🇺🇸 English"), ("vi", "🇻🇳 Tieng Viet"), ("es", "🇪🇸 Espanol"), ("fr", "🇫🇷 Francais"),
        ("de", "🇩🇪 Deutsch"), ("it", "🇮🇹 Italiano"), ("pt", "🇵🇹 Portugues"), ("ru", "🇷🇺 Russkiy"),
        ("ja", "🇯🇵 Nihongo"), ("ko", "🇰🇷 Hangug-eo"), ("zh-CN", "🇨🇳 JianTi ZhongWen"), ("zh-TW", "🇹🇼 FanTi ZhongWen"),
        ("th", "🇹🇭 Thai"), ("id", "🇮🇩 Bahasa Indonesia"), ("ms", "🇲🇾 Bahasa Melayu"), ("hi", "🇮🇳 Hindi"),
        ("ar", "🇸🇦 Arabic"), ("tr", "🇹🇷 Turkce"), ("pl", "🇵🇱 Polski"), ("nl", "🇳🇱 Nederlands")
    ]

    private let tagsApi = URL(string: "https://api.github.com/repos/trinhtanphat/SLAPMAC/tags?per_page=20")!
    private let releasesUrl = URL(string: "https://github.com/trinhtanphat/SLAPMAC/releases/latest")!

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("SlapMac \(t("preferences"))")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 8) {
                Text(t("language"))
                    .font(.headline)
                Picker(t("language"), selection: $languageCode) {
                    ForEach(languages, id: \.0) { item in
                        Text(item.1).tag(item.0)
                    }
                }
                .pickerStyle(.menu)
            }

            Text("⚠ 18+ warning: adult-oriented sound content")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.orange)
            
            Divider()
            
            // Sensitivity
            VStack(alignment: .leading, spacing: 8) {
                Text(t("detectionSensitivity"))
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
                Text(t("volume"))
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
                Text(t("cooldown"))
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
            Toggle(t("launchAtLogin"), isOn: $launchAtLogin)

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("\(t("version")): v\(currentVersion)")
                    .font(.headline)
                    .foregroundColor(.yellow)

                Text(updateStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Button(t("checkUpdate")) {
                        checkForUpdates(manual: true)
                    }
                    .disabled(isCheckingUpdate)
                    .buttonStyle(.bordered)

                    Button(t("updateNow")) {
                        NSWorkspace.shared.open(releasesUrl)
                    }
                    .disabled(!hasUpdate)
                    .buttonStyle(.borderedProminent)
                }
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button(t("reset")) {
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
        .frame(width: 420, height: 520)
        .onChange(of: sensitivity) { _ in savePreferences() }
        .onChange(of: volume) { _ in savePreferences() }
        .onChange(of: cooldown) { _ in savePreferences() }
        .onChange(of: launchAtLogin) { _ in savePreferences() }
        .onAppear { checkForUpdates(manual: false) }
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(sensitivity, forKey: "sensitivity")
        UserDefaults.standard.set(volume, forKey: "volume")
        UserDefaults.standard.set(cooldown, forKey: "cooldown")
        UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
        NotificationCenter.default.post(name: NSNotification.Name("PreferencesChanged"), object: nil)
    }

    private var hasUpdate: Bool {
        guard let latestTag else { return false }
        return compareVersions(latestTag.replacingOccurrences(of: "v", with: ""), currentVersion) > 0
    }

    private func compareVersions(_ a: String, _ b: String) -> Int {
        let av = a.split(separator: ".").map { Int($0) ?? 0 }
        let bv = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<3 {
            let ai = i < av.count ? av[i] : 0
            let bi = i < bv.count ? bv[i] : 0
            if ai > bi { return 1 }
            if ai < bi { return -1 }
        }
        return 0
    }

    private func checkForUpdates(manual: Bool) {
        isCheckingUpdate = true
        updateStatus = t("checking")

        var request = URLRequest(url: tagsApi)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("SlapMac-macOS", forHTTPHeaderField: "User-Agent")

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isCheckingUpdate = false
            }

            guard error == nil,
                  let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let data else {
                DispatchQueue.main.async {
                    updateStatus = "Update check failed. Try again later."
                    latestTag = nil
                }
                return
            }

            guard let raw = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                DispatchQueue.main.async {
                    updateStatus = "Invalid update response."
                    latestTag = nil
                }
                return
            }

            let versionTags = raw.compactMap { $0["name"] as? String }
                .filter { $0.range(of: "^v?\\d+\\.\\d+\\.\\d+$", options: .regularExpression) != nil }

            guard let newest = versionTags.first else {
                DispatchQueue.main.async {
                    updateStatus = "No release tags found."
                    latestTag = nil
                }
                return
            }

            let latestVersion = newest.replacingOccurrences(of: "v", with: "")
            let cmp = compareVersions(latestVersion, currentVersion)

            DispatchQueue.main.async {
                latestTag = newest
                if cmp > 0 {
                    updateStatus = "New version available: \(newest)"
                } else {
                    updateStatus = manual ? "You're up to date (\(newest))." : "Up to date (\(newest))."
                }
            }
        }.resume()
    }
}

private extension PreferencesView {
    func t(_ key: String) -> String {
        let vi: [String: String] = [
            "preferences": "Cai dat", "language": "Ngon ngu", "detectionSensitivity": "Do nhay phat hien", "volume": "Am luong",
            "cooldown": "Do tre (giay giua cac lan phat)", "launchAtLogin": "Khoi dong cung he thong", "version": "Phien ban",
            "checkUpdate": "Kiem tra cap nhat", "updateNow": "Cap nhat ngay", "reset": "Dat lai mac dinh", "checking": "Dang kiem tra GitHub tags..."
        ]
        let shared: [String: [String: String]] = [
            "es": ["language": "Idioma", "checkUpdate": "Buscar actualizacion", "updateNow": "Actualizar ahora"],
            "fr": ["language": "Langue", "checkUpdate": "Verifier la mise a jour", "updateNow": "Mettre a jour"],
            "de": ["language": "Sprache", "checkUpdate": "Update pruefen", "updateNow": "Jetzt updaten"],
            "it": ["language": "Lingua", "checkUpdate": "Controlla aggiornamento", "updateNow": "Aggiorna ora"],
            "pt": ["language": "Idioma", "checkUpdate": "Verificar atualizacao", "updateNow": "Atualizar agora"],
            "ru": ["language": "Yazyk", "checkUpdate": "Proverit obnovlenie", "updateNow": "Obnovit"],
            "ja": ["language": "Gengo", "checkUpdate": "Koshin chekku", "updateNow": "Ima sugu koshin"],
            "ko": ["language": "Eoneo", "checkUpdate": "Eobdeiteu hwagin", "updateNow": "Jigeum eobdeiteu"],
            "zh-CN": ["language": "Yu yan", "checkUpdate": "Jian cha geng xin", "updateNow": "Li ji geng xin"],
            "zh-TW": ["language": "Yu yan", "checkUpdate": "Jian cha geng xin", "updateNow": "Li ji geng xin"],
            "th": ["language": "Phasa", "checkUpdate": "Truat sop update", "updateNow": "Update ton ni"],
            "id": ["language": "Bahasa", "checkUpdate": "Cek pembaruan", "updateNow": "Perbarui sekarang"],
            "ms": ["language": "Bahasa", "checkUpdate": "Semak kemas kini", "updateNow": "Kemas kini sekarang"],
            "hi": ["language": "Bhasha", "checkUpdate": "Update check karo", "updateNow": "Abhi update karo"],
            "ar": ["language": "Lugha", "checkUpdate": "Tahqiq min altahdith", "updateNow": "Haddith alan"],
            "tr": ["language": "Dil", "checkUpdate": "Guncellemeyi kontrol et", "updateNow": "Simdi guncelle"],
            "pl": ["language": "Jezyk", "checkUpdate": "Sprawdz aktualizacje", "updateNow": "Aktualizuj teraz"],
            "nl": ["language": "Taal", "checkUpdate": "Controleer update", "updateNow": "Nu updaten"]
        ]
        let en: [String: String] = [
            "preferences": "Preferences", "language": "Language", "detectionSensitivity": "Detection Sensitivity", "volume": "Volume",
            "cooldown": "Cooldown (seconds between sounds)", "launchAtLogin": "Launch at Login", "version": "Version",
            "checkUpdate": "Check Update", "updateNow": "Update Now", "reset": "Reset to Defaults", "checking": "Checking GitHub tags..."
        ]
        return (languageCode == "vi" ? vi[key] : nil)
            ?? shared[languageCode]?[key]
            ?? en[key]
            ?? key
    }
}

#Preview {
    PreferencesView()
}
