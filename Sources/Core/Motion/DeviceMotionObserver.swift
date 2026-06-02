import Combine
import CoreMotion
import SwiftUI

/// Publishes normalized device tilt for holographic card effects (parallax shine).
@MainActor
final class DeviceMotionObserver: ObservableObject {
    @Published private(set) var roll: CGFloat = 0
    @Published private(set) var pitch: CGFloat = 0

    private let manager = CMMotionManager()

    var isActive: Bool { manager.isDeviceMotionAvailable }

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1 / 60
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let clampedRoll = max(-0.45, min(0.45, motion.attitude.roll / .pi))
            let clampedPitch = max(-0.45, min(0.45, motion.attitude.pitch / .pi))
            roll = CGFloat(clampedRoll)
            pitch = CGFloat(clampedPitch)
        }
    }

    func stop() {
        if manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
        }
    }
}
