import Foundation
import IOKit
import IOKit.hid

final class SlapDetector {
    
    private var hidManager: IOHIDManager?
    private var onSlapDetected: (() -> Void)?
    private var isRunning = false
    private var sensitivity: Double = 1.5
    private var cooldownInterval: TimeInterval = 1.5
    private var lastSlapTime: Date = .distantPast
    
    // For lid accelerometer approach
    private var smsConnection: io_connect_t = 0
    private var smsTimer: Timer?
    
    // Alternative: monitor trackpad force or sudden motion
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    init(onSlapDetected: @escaping () -> Void) {
        self.onSlapDetected = onSlapDetected
    }
    
    deinit {
        stopDetecting()
    }
    
    var currentSensitivity: Double {
        get { sensitivity }
        set { sensitivity = max(0.5, min(5.0, newValue)) }
    }
    
    var currentCooldown: TimeInterval {
        get { cooldownInterval }
        set { cooldownInterval = max(0.1, min(2.0, newValue)) }
    }
    
    func startDetecting() {
        guard !isRunning else { return }
        isRunning = true
        
        // Strategy 1: Try SMS (Sudden Motion Sensor) - works on older MacBooks
        if startSMSDetection() {
            NSLog("[SlapMac] Using Sudden Motion Sensor for slap detection")
            return
        }
        
        // Strategy 2: Use HID accelerometer events
        if startHIDDetection() {
            NSLog("[SlapMac] Using HID accelerometer for slap detection")
            return
        }
        
        // Strategy 3: Monitor trackpad + keyboard events as proxy for physical impact
        startEventMonitoring()
        NSLog("[SlapMac] Using event monitoring for slap detection")
    }
    
    func stopDetecting() {
        isRunning = false
        
        smsTimer?.invalidate()
        smsTimer = nil
        
        if smsConnection != 0 {
            IOServiceClose(smsConnection)
            smsConnection = 0
        }
        
        if let hidManager = hidManager {
            IOHIDManagerClose(hidManager, IOOptionBits(kIOHIDOptionsTypeNone))
            self.hidManager = nil
        }
        
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
    }
    
    // MARK: - Strategy 1: Sudden Motion Sensor
    
    private struct SMSData {
        var x: Int16
        var y: Int16
        var z: Int16
    }
    
    private func startSMSDetection() -> Bool {
        let serviceName = "SMCMotionSensor"
        let service = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching(serviceName)
        )
        
        guard service != 0 else { return false }
        
        let result = IOServiceOpen(service, mach_task_self_, 0, &smsConnection)
        IOObjectRelease(service)
        
        guard result == KERN_SUCCESS, smsConnection != 0 else {
            if smsConnection != 0 {
                IOServiceClose(smsConnection)
                smsConnection = 0
            }
            return false
        }
        
        var previousMagnitude: Double = 0
        
        smsTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self = self, self.isRunning else { return }
            
            let inputSize: Int = 0
            var outputSize: Int = MemoryLayout<SMSData>.size
            var smsData = SMSData(x: 0, y: 0, z: 0)
            
            let kr = IOConnectCallStructMethod(
                self.smsConnection,
                5,
                nil,
                inputSize,
                &smsData,
                &outputSize
            )
            
            guard kr == KERN_SUCCESS else { return }
            
            let magnitude = sqrt(
                Double(smsData.x) * Double(smsData.x) +
                Double(smsData.y) * Double(smsData.y) +
                Double(smsData.z) * Double(smsData.z)
            )
            
            let delta = abs(magnitude - previousMagnitude)
            previousMagnitude = magnitude
            
            if delta > self.sensitivity * 100 {
                self.triggerSlap()
            }
        }
        
        RunLoop.main.add(smsTimer!, forMode: .common)
        return true
    }
    
    // MARK: - Strategy 2: HID Accelerometer
    
    private func startHIDDetection() -> Bool {
        hidManager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        guard let manager = hidManager else { return false }
        
        // Match accelerometer devices
        let criteria: [[String: Any]] = [
            [
                kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey as String: 0x04 // Joystick (accelerometer appears as this)
            ],
            [
                kIOHIDDeviceUsagePageKey as String: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey as String: 0x08 // Multi-axis controller
            ],
            [
                kIOHIDDeviceUsagePageKey as String: 0x20, // Sensor
                kIOHIDDeviceUsageKey as String: 0x73  // Accelerometer 3D
            ]
        ]
        
        IOHIDManagerSetDeviceMatchingMultiple(manager, criteria as CFArray)
        
        let inputCallback: IOHIDValueCallback = { context, result, sender, value in
            guard let context = context else { return }
            let detector = Unmanaged<SlapDetector>.fromOpaque(context).takeUnretainedValue()
            
            let physValue = IOHIDValueGetScaledValue(value, IOHIDValueScaleType(kIOHIDValueScaleTypePhysical))
            
            // Check if acceleration exceeds threshold
            if abs(physValue) > detector.sensitivity {
                detector.triggerSlap()
            }
        }
        
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterInputValueCallback(manager, inputCallback, context)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        
        let openResult = IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        if openResult != kIOReturnSuccess {
            self.hidManager = nil
            return false
        }
        
        // Check if any devices were matched
        if let devices = IOHIDManagerCopyDevices(manager), CFSetGetCount(devices) > 0 {
            return true
        }
        
        IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = nil
        return false
    }
    
    // MARK: - Strategy 3: Event Monitoring (Fallback)
    // Detects sudden trackpad touches or keyboard presses that indicate physical impact
    
    private func startEventMonitoring() {
        // Monitor for sudden pressure/touch events on trackpad
        // When you slap/tap the MacBook body, the trackpad often registers phantom touches
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.pressure, .directTouch, .tabletPoint]
        ) { [weak self] event in
            guard let self = self else { return }
            
            // Pressure events from Force Touch trackpad
            if event.type == .pressure {
                let stage = event.stage
                let pressure = event.pressure
                
                // A slap creates sudden high pressure
                if stage >= 1 && pressure > Float(0.8 / self.sensitivity) {
                    self.triggerSlap()
                }
            }
        }
        
        // Also add local monitor for when app is active
        localEventMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.pressure, .directTouch, .tabletPoint]
        ) { [weak self] event in
            guard let self = self else { return event }
            
            if event.type == .pressure {
                let stage = event.stage
                let pressure = event.pressure
                
                if stage >= 1 && pressure > Float(0.8 / self.sensitivity) {
                    self.triggerSlap()
                }
            }
            return event
        }
    }
    
    // MARK: - Trigger
    
    private func triggerSlap() {
        let now = Date()
        let suppressionInterval = max(cooldownInterval * 2, 3.0)
        guard now.timeIntervalSince(lastSlapTime) >= suppressionInterval else { return }
        lastSlapTime = now
        
        DispatchQueue.main.async { [weak self] in
            self?.onSlapDetected?()
        }
    }
}
