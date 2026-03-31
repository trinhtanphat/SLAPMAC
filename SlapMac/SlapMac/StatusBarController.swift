import Cocoa
import SwiftUI
import UniformTypeIdentifiers

final class StatusBarController {
    
    private var statusItem: NSStatusItem
    private var slapDetector: SlapDetector
    private var audioManager: AudioManager
    private var slapCount: Int = 0
    private var preferencesWindow: NSWindow?
    private var donateWindow: NSWindow?
    
    init(slapDetector: SlapDetector, audioManager: AudioManager) {
        self.slapDetector = slapDetector
        self.audioManager = audioManager
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        setupStatusBarIcon()
        setupMenu()
    }
    
    private func setupStatusBarIcon() {
        if let button = statusItem.button {
            // Use SF Symbol for the status bar icon
            if let image = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "SlapMac") {
                let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                button.image = image.withSymbolConfiguration(config)
            } else {
                button.title = "👋"
            }
            button.toolTip = "SlapMac - Tap your MacBook!"
        }
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Status header
        let headerItem = NSMenuItem(title: "🖐 SlapMac", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Enable/Disable toggle
        let toggleItem = NSMenuItem(
            title: "Enabled",
            action: #selector(toggleEnabled),
            keyEquivalent: "e"
        )
        toggleItem.target = self
        toggleItem.state = .on
        toggleItem.tag = 100
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Slap counter
        let counterItem = NSMenuItem(title: "Slaps: 0", action: nil, keyEquivalent: "")
        counterItem.isEnabled = false
        counterItem.tag = 200
        menu.addItem(counterItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Sensitivity submenu
        let sensitivityMenu = NSMenu()
        let sensitivityLevels: [(String, Double)] = [
            ("Very Low (Light touch)", 0.5),
            ("Low", 1.0),
            ("Medium (Default)", 1.5),
            ("High", 2.5),
            ("Very High (Hard slap only)", 4.0)
        ]
        
        for (title, value) in sensitivityLevels {
            let item = NSMenuItem(title: title, action: #selector(setSensitivity(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            if value == 1.5 {
                item.state = .on
            }
            sensitivityMenu.addItem(item)
        }
        
        let sensitivityItem = NSMenuItem(title: "Sensitivity", action: nil, keyEquivalent: "")
        sensitivityItem.submenu = sensitivityMenu
        menu.addItem(sensitivityItem)
        
        // Volume submenu
        let volumeMenu = NSMenu()
        let volumeLevels: [(String, Float)] = [
            ("25%", 0.25),
            ("50%", 0.50),
            ("75%", 0.75),
            ("100%", 1.0)
        ]
        
        for (title, value) in volumeLevels {
            let item = NSMenuItem(title: title, action: #selector(setVolume(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = value
            if value == 1.0 {
                item.state = .on
            }
            volumeMenu.addItem(item)
        }
        
        let volumeItem = NSMenuItem(title: "Volume", action: nil, keyEquivalent: "")
        volumeItem.submenu = volumeMenu
        menu.addItem(volumeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Add custom sound
        let addSoundItem = NSMenuItem(
            title: "Add Custom Sound...",
            action: #selector(addCustomSound),
            keyEquivalent: ""
        )
        addSoundItem.target = self
        menu.addItem(addSoundItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Preferences
        let prefsItem = NSMenuItem(
            title: "Preferences...",
            action: #selector(showPreferences),
            keyEquivalent: ","
        )
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        // Donate
        let donateItem = NSMenuItem(
            title: "☕ Donate / Support",
            action: #selector(showDonate),
            keyEquivalent: "d"
        )
        donateItem.target = self
        menu.addItem(donateItem)
        
        // About
        let aboutItem = NSMenuItem(
            title: "About SlapMac",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit SlapMac",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
        
        // Update slap counter when slap happens
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("SlapDetected"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateSlapCount()
        }
    }
    
    private func updateSlapCount() {
        slapCount += 1
        if let item = statusItem.menu?.item(withTag: 200) {
            item.title = "Slaps: \(slapCount)"
        }
    }
    
    @objc private func toggleEnabled() {
        let item = statusItem.menu?.item(withTag: 100)
        if item?.state == .on {
            item?.state = .off
            item?.title = "Disabled"
            slapDetector.stopDetecting()
            audioManager.enabled = false
            
            if let button = statusItem.button {
                if let image = NSImage(systemSymbolName: "hand.tap", accessibilityDescription: "SlapMac (Disabled)") {
                    let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .light)
                    button.image = image.withSymbolConfiguration(config)
                }
            }
        } else {
            item?.state = .on
            item?.title = "Enabled"
            slapDetector.startDetecting()
            audioManager.enabled = true
            
            if let button = statusItem.button {
                if let image = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "SlapMac") {
                    let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
                    button.image = image.withSymbolConfiguration(config)
                }
            }
        }
    }
    
    @objc private func setSensitivity(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Double else { return }
        slapDetector.currentSensitivity = value
        
        // Update checkmarks
        if let menu = sender.menu {
            for item in menu.items {
                item.state = .off
            }
        }
        sender.state = .on
    }
    
    @objc private func setVolume(_ sender: NSMenuItem) {
        guard let value = sender.representedObject as? Float else { return }
        audioManager.currentVolume = value
        
        if let menu = sender.menu {
            for item in menu.items {
                item.state = .off
            }
        }
        sender.state = .on
    }
    
    @objc private func addCustomSound() {
        let panel = NSOpenPanel()
        panel.title = "Choose Audio File"
        panel.allowedContentTypes = [
            .mp3, .wav, .aiff, .audio
        ]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        
        panel.begin { [weak self] response in
            guard response == .OK else { return }
            for url in panel.urls {
                _ = self?.audioManager.addCustomSoundFromURL(url)
            }
        }
    }
    
    @objc private func showPreferences() {
        if let window = preferencesWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let prefsView = PreferencesView()
        let hostingView = NSHostingView(rootView: prefsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 450),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SlapMac Preferences"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        preferencesWindow = window
    }
    
    @objc private func showDonate() {
        if let window = donateWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let donateView = DonateView()
        let hostingView = NSHostingView(rootView: donateView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Support SlapMac ☕"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        donateWindow = window
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "SlapMac"
        alert.informativeText = """
        Version 1.0.0
        
        Slap your MacBook, hear funny sounds! 🖐💻
        
        SlapMac detects physical taps and slaps on your MacBook \
        using the built-in motion sensors and plays amusing sounds.
        
        Free & Open Source
        Made with ❤️
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        
        if let appIcon = NSImage(named: NSImage.applicationIconName) {
            alert.icon = appIcon
        }
        
        NSApp.activate(ignoringOtherApps: true)
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
