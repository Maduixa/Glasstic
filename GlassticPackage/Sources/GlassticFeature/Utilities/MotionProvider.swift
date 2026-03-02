import CoreMotion
import SwiftUI

/// Provides normalized device tilt values for parallax effects
@MainActor
public final class MotionProvider: ObservableObject {
    @Published public var normalizedTilt = CGSize.zero
    
    private let manager = CMMotionManager()
    private var currentTilt = CGSize.zero
    
    public init() {}
    
    public func start() {
        guard manager.isDeviceMotionAvailable else { return }
        if manager.isDeviceMotionActive { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let maxTilt = 0.35
            let targetX = clamp(motion.attitude.roll / maxTilt)
            let targetY = clamp(motion.attitude.pitch / maxTilt)
            let smoothing: CGFloat = 0.18
            let nextX = currentTilt.width + (targetX - currentTilt.width) * smoothing
            let nextY = currentTilt.height + (targetY - currentTilt.height) * smoothing
            let next = CGSize(width: nextX, height: nextY)
            currentTilt = next
            normalizedTilt = next
        }
    }
    
    public func stop() {
        manager.stopDeviceMotionUpdates()
        currentTilt = .zero
        normalizedTilt = .zero
    }
    
    private func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, -1.0), 1.0))
    }
}

/// Environment key for sharing motion data
private struct MotionProviderKey: EnvironmentKey {
    static let defaultValue: MotionProvider? = nil
}

public extension EnvironmentValues {
    var motionProvider: MotionProvider? {
        get { self[MotionProviderKey.self] }
        set { self[MotionProviderKey.self] = newValue }
    }
}
