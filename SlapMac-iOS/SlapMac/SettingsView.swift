import SwiftUI

struct SettingsView: View {
    @ObservedObject var detector: SlapDetector
    @ObservedObject var audio: AudioManager

    @State private var sensitivity: Double = 1.5
    @State private var volume: Double = 1.0
    @State private var cooldown: Double = 1.5
    @State private var updateStatus: String = "Checking updates..."
    @State private var latestTag: String?
    @State private var isCheckingUpdate = false
    @AppStorage("languageCode") private var languageCode: String = "en"

    @Environment(\.openURL) private var openURL

    private let bgColor = Color(red: 0.086, green: 0.086, blue: 0.149)
    private let accentRed = Color(red: 0.91, green: 0.27, blue: 0.38)
    private let tagsApi = URL(string: "https://api.github.com/repos/trinhtanphat/SLAPMAC/tags?per_page=20")!
    private let releasesUrl = URL(string: "https://github.com/trinhtanphat/SLAPMAC/releases/latest")!
    private let languages: [(String, String)] = [
        ("en", "🇺🇸 English"), ("vi", "🇻🇳 Tieng Viet"), ("es", "🇪🇸 Espanol"), ("fr", "🇫🇷 Francais"),
        ("de", "🇩🇪 Deutsch"), ("it", "🇮🇹 Italiano"), ("pt", "🇵🇹 Portugues"), ("ru", "🇷🇺 Russkiy"),
        ("ja", "🇯🇵 Nihongo"), ("ko", "🇰🇷 Hangug-eo"), ("zh-CN", "🇨🇳 JianTi ZhongWen"), ("zh-TW", "🇹🇼 FanTi ZhongWen"),
        ("th", "🇹🇭 Thai"), ("id", "🇮🇩 Bahasa Indonesia"), ("ms", "🇲🇾 Bahasa Melayu"), ("hi", "🇮🇳 Hindi"),
        ("ar", "🇸🇦 Arabic"), ("tr", "🇹🇷 Turkce"), ("pl", "🇵🇱 Polski"), ("nl", "🇳🇱 Nederlands")
    ]
    private static let bundleTranslations: [String: [String: String]] = {
        guard let url = Bundle.main.url(forResource: "i18n", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let translations = obj["translations"] as? [String: [String: String]] else {
            return [:]
        }
        return translations
    }()

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("⚙️ \(t("settings"))")
                        .font(.title.bold())
                        .foregroundColor(accentRed)
                        .frame(maxWidth: .infinity, alignment: .center)

                    VStack(alignment: .leading, spacing: 8) {
                        Text(t("language"))
                            .foregroundColor(.white)
                        Picker(t("language"), selection: $languageCode) {
                            ForEach(languages, id: \.0) { item in
                                Text(item.1).tag(item.0)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    // Sensitivity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(t("sensitivity")): \(String(format: "%.1f", sensitivity))")
                            .foregroundColor(.white)
                        Slider(value: $sensitivity, in: 0.5...4.0, step: 0.1)
                            .tint(accentRed)
                            .onChange(of: sensitivity) {
                                detector.sensitivity = sensitivity
                            }
                    }

                    // Volume
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(t("volume")): \(Int(volume * 100))%")
                            .foregroundColor(.white)
                        Slider(value: $volume, in: 0...1, step: 0.01)
                            .tint(accentRed)
                            .onChange(of: volume) {
                                audio.volume = Float(volume)
                            }
                    }

                    // Cooldown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(t("cooldown")): \(Int(cooldown * 1000))ms")
                            .foregroundColor(.white)
                        Slider(value: $cooldown, in: 0.5...5.0, step: 0.1)
                            .tint(accentRed)
                            .onChange(of: cooldown) {
                                detector.cooldownInterval = cooldown
                            }
                    }

                    // Reset
                    Button(t("reset")) {
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

                    // Version updates
                    VStack(alignment: .leading, spacing: 10) {
                        Text("\(t("version")): v\(currentVersion)")
                            .foregroundColor(.yellow)
                            .font(.subheadline.bold())

                        Text(updateStatus)
                            .foregroundColor(.gray)
                            .font(.caption)

                        HStack(spacing: 10) {
                            Button(t("checkUpdate")) {
                                checkForUpdates(manual: true)
                            }
                            .disabled(isCheckingUpdate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(10)

                            Button(t("updateNow")) {
                                openURL(releasesUrl)
                            }
                            .disabled(!hasUpdate)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(hasUpdate ? Color.orange : Color.white.opacity(0.08))
                            .foregroundColor(hasUpdate ? .black : .gray)
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
        }
        .onAppear {
            sensitivity = detector.sensitivity
            volume = Double(audio.volume)
            cooldown = detector.cooldownInterval
            checkForUpdates(manual: false)
        }
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
        request.setValue("SlapMac-iOS", forHTTPHeaderField: "User-Agent")

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
                    updateStatus = manual ? t("upToDateYou").replacingOccurrences(of: "{tag}", with: newest) : t("upToDate").replacingOccurrences(of: "{tag}", with: newest)
                }
            }
        }.resume()
    }

    private func t(_ key: String) -> String {
        if let value = Self.bundleTranslations[languageCode]?[key], !value.isEmpty {
            return value
        }
        if let value = Self.bundleTranslations["en"]?[key], !value.isEmpty {
            return value
        }

        let vi: [String: String] = [
            "settings": "Cai dat", "language": "Ngon ngu", "sensitivity": "Do nhay", "volume": "Am luong", "cooldown": "Do tre",
            "reset": "Dat lai mac dinh", "version": "Phien ban", "checkUpdate": "Kiem tra cap nhat", "updateNow": "Cap nhat ngay",
            "checking": "Dang kiem tra GitHub tags...", "upToDate": "Da moi nhat ({tag}).", "upToDateYou": "Ban dang o ban moi nhat ({tag})."
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
            "settings": "Settings", "language": "Language", "sensitivity": "Sensitivity", "volume": "Volume", "cooldown": "Cooldown",
            "reset": "Reset to Defaults", "version": "Version", "checkUpdate": "Check Update", "updateNow": "Update Now",
            "checking": "Checking GitHub tags...", "upToDate": "Up to date ({tag}).", "upToDateYou": "You're up to date ({tag})."
        ]
        return (languageCode == "vi" ? vi[key] : nil)
            ?? shared[languageCode]?[key]
            ?? en[key]
            ?? key
    }
}
