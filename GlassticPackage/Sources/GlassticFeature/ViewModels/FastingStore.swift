import SwiftUI

@MainActor
@Observable
public final class FastingStore {
    public private(set) var activeSession: FastingSession?
    public private(set) var elapsed: TimeInterval = 0
    private var timer: Timer?

    private let dataService = DataService.shared
    public let targetDuration: TimeInterval

    public init(targetDuration: TimeInterval = 16 * 3600) {
        self.targetDuration = targetDuration
        loadActiveSession()
        if activeSession != nil {
            startTimer()
        }
    }

    public var progress: Double {
        guard elapsed > 0 else { return 0 }
        return min(elapsed / targetDuration, 1.0)
    }

    public var isActive: Bool {
        activeSession != nil
    }

    public func startFast() {
        activeSession = dataService.startFast()
        elapsed = 0
        startTimer()
    }

    public func endFast() {
        guard let session = activeSession else { return }
        dataService.endFast(session)
        stopTimer()
        activeSession = nil
        elapsed = 0
    }

    private func loadActiveSession() {
        activeSession = dataService.fetchActiveFast()
        if let session = activeSession {
            elapsed = session.duration
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsed()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsed() {
        guard let session = activeSession else { return }
        elapsed = session.duration
    }
}
