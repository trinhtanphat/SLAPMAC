# 🖐 SlapMac

**Slap your laptop, hear funny sounds!**

SlapMac detects physical taps and slaps on your laptop/phone and plays amusing sound effects. Available as a **macOS app**, **Windows app**, **iOS app**, **Android app**, **Linux app**, and **Chrome browser extension**.

> ⚠️ 18+ Warning: This app includes adult-oriented sound content. Use responsibly.

[![Build & Release](../../actions/workflows/release.yml/badge.svg)](../../actions/workflows/release.yml)

---

## 📦 Download

| Platform | Download | Architecture |
|----------|----------|--------------|
| 🍎 macOS | [SlapMac-macOS.dmg](../../releases/latest) | Universal (Intel + Apple Silicon) |
| 🪟 Windows | [SlapMac-Windows-x64.zip](../../releases/latest) | x64 |
| 🪟 Windows | [SlapMac-Windows-arm64.zip](../../releases/latest) | ARM64 |
| 📱 iOS | [SlapMac-iOS.zip](../../releases/latest) | iPhone + iPad |
| 🤖 Android | [SlapMac-Android.apk](../../releases/latest) | All devices |
| 🐧 Linux | [SlapMac-Linux.zip](../../releases/latest) | x64 |
| 🌐 Chrome | [SlapMac-Extension.zip](../../releases/latest) | All browsers |

> All releases include `SHA256SUMS.txt` for integrity verification.

---

## 🔐 Verify Downloads (SHA256)

Every release includes SHA256 checksums. **Always verify before running.**

**macOS / Linux:**
```bash
# Verify all files at once
sha256sum -c SHA256SUMS.txt

# Or verify a single file
sha256sum SlapMac-macOS.dmg
```

**Windows PowerShell:**
```powershell
# Get hash of downloaded file
Get-FileHash .\SlapMac-Windows-x64.zip -Algorithm SHA256

# Compare with value in SHA256SUMS.txt
Get-Content .\SHA256SUMS.txt
```

---

## 🎯 Features

- 🖐 **Slap Detection** — Detects physical taps on your laptop
- 🔊 **Funny Sounds** — Plays random sounds when a slap is detected
- 🎚️ **Adjustable Sensitivity** — From light touch to hard slap
- 🔈 **Volume Control** — Adjust playback volume
- ⏱️ **Cooldown Timer** — Prevent rapid-fire sounds
- 📊 **Slap Counter** — Track total slaps
- 🎵 **Custom Sounds** — Add your own audio files
- ☕ **Donate** — Support via MoMo & Techcombank QR codes
- 🆓 **100% Free** — No ads, no subscriptions, open source

---

## 🍎 macOS App

### Requirements
- macOS 13.0 (Ventura) or later
- MacBook with built-in sensors

### How It Works
The app lives in your **menu bar** (no Dock icon) and uses a 3-strategy detection approach:

1. **Sudden Motion Sensor (SMS)** — Built-in accelerometer on older MacBooks
2. **HID Accelerometer** — IOKit HID interface for newer hardware
3. **Trackpad Pressure (Fallback)** — Detects phantom trackpad events from physical impact

### Install
1. Download `SlapMac-macOS.dmg` from [Releases](../../releases/latest)
2. Open DMG → Drag `SlapMac.app` to Applications
3. Launch — appears in **menu bar** (top right)
4. Slap your MacBook! 🖐💥

### Build from Source
```bash
# Copy resources
mkdir -p SlapMac/SlapMac/Resources
cp audio/* SlapMac/SlapMac/Resources/
cp qrcode/* SlapMac/SlapMac/Resources/

# Build
cd SlapMac
xcodebuild -project SlapMac.xcodeproj -scheme SlapMac -configuration Release build
```

---

## 🪟 Windows App

### Requirements
- Windows 10 or later
- Microphone access (for tap detection)

### How It Works
Uses **microphone-based detection** — analyzes audio amplitude spikes from physical taps on the laptop body. Features:
- Adaptive baseline calibration (adjusts to ambient noise)
- RMS amplitude analysis at 44.1kHz
- Audio feedback loop prevention (suppression window)
- Configurable sensitivity and cooldown

### Install
1. Download `SlapMac-Windows-x64.zip` from [Releases](../../releases/latest)
2. Extract to any folder
3. Run `SlapMac.exe`
4. App appears in **system tray** (bottom right)
5. Slap your laptop! 🖐💥

### Build from Source
```powershell
# Build (resources are copied automatically from audio/ and qrcode/)
dotnet publish SlapMac-Windows/SlapMac.csproj -c Release -r win-x64 --self-contained true -p:PublishSingleFile=true -o publish
```

Requires [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0).

---

## 📱 iOS App

### Requirements
- iOS 17.0 or later
- iPhone or iPad with accelerometer

### How It Works
Uses **CoreMotion accelerometer** to detect physical taps. Features:
- Adaptive baseline calibration (50 samples at startup)
- Real-time magnitude calculation vs dynamic baseline
- Extended suppression window to prevent multi-triggers
- SwiftUI interface with tabs: Home, Settings, Donate

### Install
1. Download `SlapMac-iOS.zip` from [Releases](../../releases/latest)
2. Requires Xcode for sideloading or TestFlight distribution
3. Open the project and build to your device

### Build from Source
```bash
# Install XcodeGen
brew install xcodegen

# Copy resources
mkdir -p SlapMac-iOS/SlapMac/Resources
cp audio/* SlapMac-iOS/SlapMac/Resources/
cp qrcode/* SlapMac-iOS/SlapMac/Resources/

# Generate Xcode project & build
cd SlapMac-iOS
xcodegen generate
xcodebuild -project SlapMac-iOS.xcodeproj -scheme SlapMac -configuration Release -sdk iphoneos
```

---

## 🤖 Android App

### Requirements
- Android 8.0 (API 26) or later
- Device with accelerometer sensor

### How It Works
Uses **SensorManager TYPE_ACCELEROMETER** at game-speed polling rate. Features:
- Calibration phase with dynamic baseline
- Adaptive sensitivity based on ambient vibration
- Extended suppression window (same algorithm as all platforms)
- Material3 dark theme UI

### Install
1. Download `SlapMac-Android.apk` from [Releases](../../releases/latest)
2. Enable "Install unknown apps" in your device settings
3. Open the APK to install
4. Tap your phone! 🖐💥

### Build from Source
```bash
# Copy audio assets
mkdir -p SlapMac-Android/app/src/main/assets/audio
cp audio/* SlapMac-Android/app/src/main/assets/audio/

# Build
cd SlapMac-Android
./gradlew assembleDebug
```

Requires JDK 17 and Android SDK.

---

## 🐧 Linux App

### Requirements
- Python 3.8+
- PortAudio (for microphone input)
- Tkinter (for GUI)

### How It Works
Uses **sounddevice + numpy** for microphone-based RMS detection. Features:
- Adaptive baseline with rolling average
- Post-suppression recalibration (same as Windows)
- Extended suppression window to prevent multi-triggers
- Tkinter dark-themed GUI

### Install (Quick)
```bash
cd SlapMac-Linux
chmod +x install.sh
./install.sh
```

### Install (Manual)
```bash
# Install system dependencies
sudo apt install python3-pip python3-venv python3-tk libportaudio2 portaudio19-dev

# Copy resources
mkdir -p SlapMac-Linux/resources
cp audio/* SlapMac-Linux/resources/

# Install Python packages
pip install -r SlapMac-Linux/requirements.txt

# Run
cd SlapMac-Linux
python3 slapmac.py
```

---

## 🌐 Chrome Extension

### Requirements
- Chrome, Edge, Brave, or any Chromium browser
- Laptop with motion sensors OR microphone

### Important Before Install
- This extension is not on the Chrome Web Store yet
- There is no built-in setup wizard in the browser
- You must load it manually as an unpacked extension from a folder containing `manifest.json`

### Detection Modes
| Mode | API | Best For |
|------|-----|----------|
| **Motion Sensor** | DeviceMotion API | Laptops with accelerometers |
| **Microphone** | Web Audio API | Any laptop with mic |

### Install
#### Option A: Install from Release ZIP
1. Download `SlapMac-Extension.zip` from [Releases](../../releases/latest)
2. Extract the ZIP completely
3. Open the extracted folder and confirm it contains `manifest.json`, `background/`, `popup/`, and `icons/`

#### Option B: Install directly from this source repo
1. Clone this repo and open folder `SlapMac-Extension/`
2. Confirm files exist: `manifest.json`, `popup/`, `background/`, `icons/`
3. If PNG icons are missing in `icons/`, run `generate-icons.sh` (or use existing `icon16.png`, `icon48.png`, `icon128.png`)

#### Load Unpacked (by browser)
- **Chrome:** open `chrome://extensions`
- **Edge:** open `edge://extensions`
- **Brave:** open `brave://extensions`

Then:
1. Enable **Developer mode**
2. Click **Load unpacked**
3. Select folder `SlapMac-Extension`
4. Pin SlapMac from extensions menu
5. Click the SlapMac icon to open popup
6. Choose **Microphone** mode (recommended for desktop/laptop)
7. Allow microphone permission when browser asks

#### First-run Checklist
- Status shows **Enabled**
- Detection mode is **Microphone (Desktop)**
- Popup remains open while testing
- Press **Test Sound** once to confirm audio playback
- Tap/slap device and verify counter increases

### How To Use
- Keep the popup open while detection is running
- Use **Microphone** mode on most desktops and laptops
- Use **Motion Sensor** only if your browser/device exposes motion data
- Increase cooldown if one hit triggers too many sounds

### Common Issues
- If you only downloaded the ZIP but did not extract it: the browser cannot load it
- If **Load unpacked** fails: select the folder that directly contains `manifest.json`
- If the icon is missing: pin SlapMac from the browser extensions menu
- If the popup closes: slap detection stops
- If no sound plays: check tab/browser audio is not muted and press **Test Sound**
- If microphone was denied: open site/extension permissions and allow microphone, then reopen popup
- If you want one-click install: this must be published to the Chrome Web Store first

### Publisher Notes
- Privacy policy draft: `SlapMac-Extension/PRIVACY-POLICY.md`
- Chrome Web Store checklist and listing draft: `SlapMac-Extension/WEB-STORE.md`

### Features
- Dark gradient UI with animations
- Toggle between Motion/Microphone detection
- Real-time slap counter
- Adjustable sensitivity, volume, cooldown
- Test sound button
- Donate modal with QR codes

---

## 📁 Project Structure

```
SLAPMAC/
├── audio/                          # Sound files
│   ├── moan-female-active.mp3
│   └── gentle-feminine-groan.mp3
├── qrcode/                         # Donation QR codes
│   ├── momo.jpeg
│   └── techcombank.jpeg
├── SlapMac/                        # macOS Native App (Swift)
│   ├── SlapMac.xcodeproj/
│   └── SlapMac/
│       ├── AppDelegate.swift
│       ├── SlapDetector.swift      # 3-strategy motion detection
│       ├── AudioManager.swift      # Sound playback + custom sounds
│       ├── StatusBarController.swift # Menu bar UI
│       ├── PreferencesView.swift   # Settings (SwiftUI)
│       ├── DonateView.swift        # Donate QR codes (SwiftUI)
│       ├── Info.plist
│       ├── SlapMac.entitlements
│       └── Assets.xcassets/
├── SlapMac-Windows/                # Windows App (.NET 8 WinForms)
│   ├── SlapMac.csproj
│   ├── Program.cs                  # Entry point + single instance
│   ├── SlapDetector.cs             # Microphone-based detection
│   ├── AudioManager.cs             # NAudio playback
│   ├── MainForm.cs                 # Main window UI
│   ├── SettingsForm.cs             # Settings window
│   ├── TrayApp.cs                  # System tray UI
│   └── DonateForm.cs               # Donate window
├── SlapMac-iOS/                    # iOS App (SwiftUI + CoreMotion)
│   ├── project.yml                 # XcodeGen config
│   └── SlapMac/
│       ├── SlapMacApp.swift        # App entry point
│       ├── ContentView.swift       # Main UI with tabs
│       ├── SlapDetector.swift      # CoreMotion accelerometer
│       ├── AudioManager.swift      # AVAudioPlayer playback
│       ├── SettingsView.swift      # Settings tab
│       ├── DonateView.swift        # Donate tab
│       ├── Info.plist
│       └── Assets.xcassets/
├── SlapMac-Android/                # Android App (Kotlin)
│   ├── build.gradle.kts
│   ├── settings.gradle.kts
│   └── app/
│       ├── build.gradle.kts
│       └── src/main/
│           ├── AndroidManifest.xml
│           ├── kotlin/com/slapmac/
│           │   ├── MainActivity.kt
│           │   ├── SlapDetector.kt # SensorManager accelerometer
│           │   └── AudioManager.kt # MediaPlayer from assets
│           └── res/
│               ├── layout/activity_main.xml
│               └── values/
├── SlapMac-Linux/                  # Linux App (Python + tkinter)
│   ├── slapmac.py                  # Main GUI
│   ├── slap_detector.py            # sounddevice mic detection
│   ├── audio_manager.py            # pygame playback
│   ├── requirements.txt
│   └── install.sh                  # Auto-installer
├── SlapMac-Extension/              # Chrome Extension (Manifest V3)
│   ├── manifest.json
│   ├── background/service-worker.js
│   ├── popup/
│   │   ├── popup.html
│   │   ├── popup.css
│   │   └── popup.js
│   └── icons/
├── .github/workflows/
│   └── release.yml                 # CI/CD: Build + Release + SHA256
├── build.sh                        # Local build script
├── .gitignore
└── README.md
```

---

## 🚀 CI/CD

Automated builds via GitHub Actions.

### Trigger a Release
```bash
# 1) One command to sync all version files
powershell -ExecutionPolicy Bypass -File ./bump-version.ps1 1.0.12

# 2) Commit
git add -A
git commit -m "chore: release v1.0.12"

# 3) Tag and push to trigger automatic build + release
git tag v1.0.12
git push origin main
git push origin v1.0.12
```

Release workflow is tag-driven only (`vX.Y.Z`) and will fail if any app version does not match the pushed tag.

### What the CI/CD Does
1. **macOS Job** — Builds Universal binary (arm64 + x86_64), creates DMG + ZIP
2. **Windows Job** — Builds .NET 8 self-contained EXE for x64 and ARM64
3. **Extension Job** — Validates manifest, generates icons, packages ZIP
4. **iOS Job** — Generates Xcode project via XcodeGen, builds for iphoneos
5. **Android Job** — Sets up JDK 17 + Gradle, builds debug APK
6. **Linux Job** — Sets up Python 3.11, validates imports, packages ZIP
7. **Release Job** — Generates SHA256 checksums, creates GitHub Release with all artifacts

### Security Measures
- ✅ SHA256 checksums for all release artifacts
- ✅ Checksum verification step in CI pipeline
- ✅ Content Security Policy in extension
- ✅ App Sandbox + Hardened Runtime (macOS)
- ✅ Filename sanitization for custom sounds (path traversal prevention)
- ✅ Audio file extension whitelist validation
- ✅ Version update checks use GitHub API only (`api.github.com`)
- ✅ Extension uses minimal permissions (`storage` only)
- ✅ Single-instance enforcement (Windows)
- ✅ No private APIs used

---

## 🍎 Mac App Store Notes

For App Store distribution:

1. **Apple Developer Account** ($99/year)
2. Set **Team ID** in Xcode → Signing & Capabilities
3. Already configured:
   - ✅ App Sandbox enabled
   - ✅ Hardened Runtime enabled
   - ✅ Privacy descriptions (NSMotionUsageDescription)
   - ✅ LSUIElement (menu bar app, no Dock icon)
   - ✅ No private APIs
   - ✅ No data collection

### Notarization (direct distribution)
```bash
xcrun notarytool submit SlapMac.dmg \
  --apple-id YOUR_APPLE_ID \
  --team-id YOUR_TEAM_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD \
  --wait

xcrun stapler staple SlapMac.dmg
```

---

## 🎵 Adding Custom Sounds

| Platform | How |
|----------|-----|
| macOS | Menu bar → Add Custom Sound... → select files |
| Windows | System tray → Add Custom Sound... → select files |
| iOS | Sounds bundled in app (add via Xcode) |
| Android | Add files to `assets/audio/` folder → rebuild |
| Linux | GUI → Add Custom Sound button → select files |
| Extension | Add files to `audio/` folder → update `popup.js` → reload |

Supported formats: MP3, WAV, AIFF, M4A, AAC, CAF (macOS/iOS), WMA, OGG (Windows/Linux/Android)

---

## ☕ Support

SlapMac is **free** and always will be!

If you enjoy it, consider supporting via the in-app donate screen (MoMo & Techcombank QR codes).

---

## 📄 License

Free to use and modify. Made with ❤️
