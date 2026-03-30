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
        
        slapDetector?.startDetecting()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        slapDetector?.stopDetecting()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
