# 🖐 SlapMac

**Slap your laptop, hear funny sounds!**

SlapMac detects physical taps and slaps on your laptop and plays amusing sound effects. Available as a **macOS app**, **Windows app**, and **Chrome browser extension**.

[![Build & Release](../../actions/workflows/release.yml/badge.svg)](../../actions/workflows/release.yml)

---

## 📦 Download

| Platform | Download | Architecture |
|----------|----------|--------------|
| 🍎 macOS | [SlapMac-macOS.dmg](../../releases/latest) | Universal (Intel + Apple Silicon) |
| 🪟 Windows | [SlapMac-Windows-x64.zip](../../releases/latest) | x64 |
| 🪟 Windows | [SlapMac-Windows-arm64.zip](../../releases/latest) | ARM64 |
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

## 🌐 Chrome Extension

### Requirements
- Chrome, Edge, Brave, or any Chromium browser
- Laptop with motion sensors OR microphone

### Detection Modes
| Mode | API | Best For |
|------|-----|----------|
| **Motion Sensor** | DeviceMotion API | Laptops with accelerometers |
| **Microphone** | Web Audio API | Any laptop with mic |

### Install
1. Download `SlapMac-Extension.zip` from [Releases](../../releases/latest)
2. Extract to a folder
3. Open `chrome://extensions`
4. Enable **Developer mode** (top right)
5. Click **Load unpacked** → select the extracted folder
6. Click the SlapMac icon in toolbar

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
│   ├── TrayApp.cs                  # System tray UI
│   └── DonateForm.cs               # Donate window
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
# Tag and push to trigger automatic build + release
git tag v1.0.0
git push origin v1.0.0
```

Or use **Actions → Run workflow** for manual dispatch.

### What the CI/CD Does
1. **macOS Job** — Builds Universal binary (arm64 + x86_64), creates DMG + ZIP
2. **Windows Job** — Builds .NET 8 self-contained EXE for x64 and ARM64
3. **Extension Job** — Validates manifest, generates icons, packages ZIP
4. **Release Job** — Generates SHA256 checksums, creates GitHub Release with all artifacts

### Security Measures
- ✅ SHA256 checksums for all release artifacts
- ✅ Checksum verification step in CI pipeline
- ✅ Content Security Policy in extension
- ✅ App Sandbox + Hardened Runtime (macOS)
- ✅ Filename sanitization for custom sounds (path traversal prevention)
- ✅ Audio file extension whitelist validation
- ✅ No external network requests (fully offline)
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
| Extension | Add files to `audio/` folder → update `popup.js` → reload |

Supported formats: MP3, WAV, AIFF, M4A, AAC, CAF (macOS), WMA, OGG (Windows)

---

## ☕ Support

SlapMac is **free** and always will be!

If you enjoy it, consider supporting via the in-app donate screen (MoMo & Techcombank QR codes).

---

## 📄 License

Free to use and modify. Made with ❤️
