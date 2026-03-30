import Foundation
import AVFoundation
import AppKit

final class AudioManager {
    
    private var audioPlayers: [AVAudioPlayer] = []
    private var soundFiles: [URL] = []
    private var volume: Float = 1.0
    private var isEnabled = true
    
    init() {
        loadSounds()
    }
    
    var currentVolume: Float {
        get { volume }
        set {
            volume = max(0.0, min(1.0, newValue))
        }
    }
    
    var enabled: Bool {
        get { isEnabled }
        set { isEnabled = newValue }
    }
    
    var soundCount: Int {
        return soundFiles.count
    }
    
    private func loadSounds() {
        let bundle = Bundle.main
        
        // Load all supported audio files from the bundle
        let supportedExtensions = ["mp3", "wav", "aiff", "m4a", "caf", "aac"]
        
        for ext in supportedExtensions {
            if let urls = bundle.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                soundFiles.append(contentsOf: urls)
            }
        }
        
        // Also check Resources subdirectory
        for ext in supportedExtensions {
            if let urls = bundle.urls(forResourcesWithExtension: ext, subdirectory: "Resources") {
                soundFiles.append(contentsOf: urls)
            }
        }
        
        if soundFiles.isEmpty {
            NSLog("[SlapMac] Warning: No audio files found in bundle")
        } else {
            NSLog("[SlapMac] Loaded \(soundFiles.count) sound(s)")
        }
        
        // Pre-load audio players for better responsiveness
        preloadPlayers()
    }
    
    private func preloadPlayers() {
        audioPlayers.removeAll()
        
        for url in soundFiles {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                player.volume = volume
                audioPlayers.append(player)
            } catch {
                NSLog("[SlapMac] Failed to load audio: \(url.lastPathComponent) - \(error.localizedDescription)")
            }
        }
    }
    
    func playRandomSound() {
        guard isEnabled, !audioPlayers.isEmpty else { return }
        
        let index = Int.random(in: 0..<audioPlayers.count)
        let player = audioPlayers[index]
        
        player.volume = volume
        player.currentTime = 0
        player.play()
        
        NSLog("[SlapMac] Playing: \(soundFiles[index].lastPathComponent)")
    }
    
    func addCustomSoundFromURL(_ url: URL) -> Bool {
        do {
            // Sanitize filename - strip path traversal characters
            let rawName = url.lastPathComponent
            let sanitized = rawName
                .replacingOccurrences(of: "..", with: "")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "\\", with: "_")
            guard !sanitized.isEmpty else {
                NSLog("[SlapMac] Invalid filename")
                return false
            }
            
            // Validate it's actually an audio file
            let allowedExtensions = Set(["mp3", "wav", "aiff", "m4a", "caf", "aac"])
            guard allowedExtensions.contains(url.pathExtension.lowercased()) else {
                NSLog("[SlapMac] Unsupported audio format: \(url.pathExtension)")
                return false
            }
            
            // Copy to app support directory
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            let slapMacDir = appSupport.appendingPathComponent("SlapMac/Sounds", isDirectory: true)
            
            try FileManager.default.createDirectory(at: slapMacDir, withIntermediateDirectories: true)
            
            let destURL = slapMacDir.appendingPathComponent(sanitized)
            
            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            
            try FileManager.default.copyItem(at: url, to: destURL)
            
            let player = try AVAudioPlayer(contentsOf: destURL)
            player.prepareToPlay()
            player.volume = volume
            
            soundFiles.append(destURL)
            audioPlayers.append(player)
            
            NSLog("[SlapMac] Added custom sound: \(url.lastPathComponent)")
            return true
        } catch {
            NSLog("[SlapMac] Failed to add custom sound: \(error.localizedDescription)")
            return false
        }
    }
}
