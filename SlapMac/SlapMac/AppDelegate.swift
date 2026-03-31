import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController?
    private var slapDetector: SlapDetector?
    private var audioManager: AudioManager?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        audioManager = AudioManager()
        
        slapDetector = SlapDetector { [weak self] in
            self?.audioManager?.playRandomSound()
            NotificationCenter.default.post(name: NSNotification.Name("SlapDetected"), object: nil)
        }
        
        statusBarController = StatusBarController(
            slapDetector: slapDetector!,
            audioManager: audioManager!
        )
        
        // Listen for preference changes from PreferencesView
        NotificationCenter.default.addObserver(forName: NSNotification.Name("PreferencesChanged"), object: nil, queue: .main) { [weak self] _ in
            let defaults = UserDefaults.standard
            let sens = defaults.double(forKey: "sensitivity")
            let vol = defaults.double(forKey: "volume")
            let cool = defaults.double(forKey: "cooldown")
            if sens > 0 { self?.slapDetector?.currentSensitivity = sens }
            if vol > 0 { self?.audioManager?.currentVolume = Float(vol) }
            if cool > 0 { self?.slapDetector?.currentCooldown = cool }
        }
        
        slapDetector?.startDetecting()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        slapDetector?.stopDetecting()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
