import Foundation
import CoreMotion

final class SlapDetector: ObservableObject {
    private let motionManager = CMMotionManager()
    private let processingQueue = OperationQueue()

    private var lastSlapTime = Date.distantPast
    private var previousMagnitude: Double = 0
    private var baselineMagnitude: Double = 1.0
    private var calibrationCount = 0
    private let calibrationTotal = 50

    @Published var isRunning = false

    var sensitivity: Double = 1.5
    var cooldownInterval: TimeInterval = 1.5
    var onSlapDetected: (() -> Void)?

    var isAvailable: Bool {
        motionManager.isAccelerometerAvailable
    }

    init() {
        processingQueue.name = "com.slapmac.motion"
        processingQueue.maxConcurrentOperationCount = 1
    }

    func start() {
        guard motionManager.isAccelerometerAvailable, !isRunning else { return }

        DispatchQueue.main.async { self.isRunning = true }
        calibrationCount = 0
        baselineMagnitude = 1.0

        motionManager.accelerometerUpdateInterval = 0.01
        motionManager.startAccelerometerUpdates(to: processingQueue) { [weak self] data, _ in
            guard let self, let data else { return }
            self.processAcceleration(data.acceleration)
        }
    }

    func stop() {
        motionManager.stopAccelerometerUpdates()
        DispatchQueue.main.async { self.isRunning = false }
    }

    private func processAcceleration(_ accel: CMAcceleration) {
        let magnitude = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)

        // Calibration phase
        if calibrationCount < calibrationTotal {
            baselineMagnitude = max(baselineMagnitude, magnitude)
            calibrationCount += 1
            previousMagnitude = magnitude
            return
        }

        let delta = abs(magnitude - previousMagnitude)
        previousMagnitude = magnitude

        // Slowly adapt baseline to ambient motion
        baselineMagnitude = baselineMagnitude * 0.98 + magnitude * 0.02

        // Detection threshold inversely proportional to sensitivity
        let threshold = 2.0 / max(0.5, min(4.0, sensitivity))

        if delta > threshold {
            let now = Date()
            // Extended suppression to guarantee 1 slap = 1 sound
            let suppressionInterval = max(cooldownInterval * 2, 3.0)
            guard now.timeIntervalSince(lastSlapTime) >= suppressionInterval else { return }
            lastSlapTime = now

            DispatchQueue.main.async {
                self.onSlapDetected?()
            }
        }
    }
}
