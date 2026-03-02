import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    @Published private(set) var isReachable = false
    @Published private(set) var lastSyncDate: Date?

    private var session: WCSession?
    private var cancellables = Set<AnyCancellable>()

    override private init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    // MARK: - Send to iOS

    func startFast() {
        guard let session, session.isReachable else { return }

        let message: [String: Any] = [
            "action": "startFast",
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send start fast: \(error.localizedDescription)")
        }

        // Provide haptic feedback
        WKInterfaceDevice.current().play(.start)
    }

    func endFast() {
        guard let session, session.isReachable else { return }

        let message: [String: Any] = [
            "action": "endFast",
            "timestamp": Date().timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to send end fast: \(error.localizedDescription)")
        }

        // Provide haptic feedback
        WKInterfaceDevice.current().play(.success)
    }

    func requestSync() {
        guard let session, session.isReachable else { return }

        let message: [String: Any] = ["action": "requestSync"]

        session.sendMessage(message, replyHandler: { [weak self] reply in
            Task { @MainActor in
                self?.handleSyncResponse(reply)
            }
        }) { error in
            print("Failed to request sync: \(error.localizedDescription)")
        }
    }

    // MARK: - Application Context

    func updateApplicationContext(_ context: [String: Any]) {
        guard let session else { return }

        do {
            try session.updateApplicationContext(context)
            lastSyncDate = Date()
        } catch {
            print("Failed to update context: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func handleSyncResponse(_ reply: [String: Any]) {
        guard let activeSession = reply["activeSession"] as? [String: Any] else {
            // No active session
            WatchFastingStore.shared.clearActiveSession()
            return
        }

        // Parse active session
        guard let startTimestamp = activeSession["startDate"] as? TimeInterval else { return }
        let endTimestamp = activeSession["endDate"] as? TimeInterval
        let note = activeSession["note"] as? String ?? ""

        let startDate = Date(timeIntervalSince1970: startTimestamp)
        let endDate = endTimestamp.map { Date(timeIntervalSince1970: $0) }

        // Parse thresholds
        var thresholds = FastingThresholds.default
        if let thresholdsData = reply["thresholds"] as? [String: Double] {
            thresholds = FastingThresholds(
                postMealEndHours: thresholdsData["postMealEnd"] ?? 4,
                earlyFastingEndHours: thresholdsData["earlyFastingEnd"] ?? 12,
                fatBurningEndHours: thresholdsData["fatBurningEnd"] ?? 18
            )
        }

        // Parse streak
        let streak = reply["streak"] as? Int ?? 0

        WatchFastingStore.shared.updateFromSync(
            startDate: startDate,
            endDate: endDate,
            note: note,
            thresholds: thresholds,
            streak: streak
        )

        lastSyncDate = Date()
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if activationState == .activated {
                requestSync()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            if session.isReachable {
                requestSync()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            handleReceivedMessage(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            handleSyncResponse(applicationContext)
        }
    }

    @MainActor
    private func handleReceivedMessage(_ message: [String: Any]) {
        guard let action = message["action"] as? String else { return }

        switch action {
        case "sessionStarted":
            if let startTimestamp = message["startDate"] as? TimeInterval {
                let startDate = Date(timeIntervalSince1970: startTimestamp)
                WatchFastingStore.shared.startFast(startDate: startDate)
            }

        case "sessionEnded":
            WatchFastingStore.shared.endFast()

        case "syncUpdate":
            handleSyncResponse(message)

        default:
            break
        }
    }
}
