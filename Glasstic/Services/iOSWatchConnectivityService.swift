import Foundation
import WatchConnectivity
import Combine

@MainActor
final class IOSWatchConnectivityService: NSObject, ObservableObject {
    static let shared = IOSWatchConnectivityService()

    @Published private(set) var isWatchReachable = false
    @Published private(set) var lastSyncDate: Date?

    private var session: WCSession?
    private weak var fastingStore: FastingStore?

    override private init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func configure(with store: FastingStore) {
        self.fastingStore = store
        syncToWatch()
    }

    // MARK: - Sync to Watch

    func syncToWatch() {
        guard let session, session.isPaired, session.isWatchAppInstalled else { return }
        guard let store = fastingStore else { return }

        var context: [String: Any] = [
            "streak": store.streakCount
        ]

        // Sync active session
        if let activeSession = store.activeSession {
            context["activeSession"] = [
                "startDate": activeSession.startDate.timeIntervalSince1970,
                "note": activeSession.note
            ]
        }

        // Sync thresholds
        context["thresholds"] = [
            "postMealEnd": store.thresholds.postMealEndHours,
            "earlyFastingEnd": store.thresholds.earlyFastingEndHours,
            "fatBurningEnd": store.thresholds.fatBurningEndHours
        ]

        do {
            try session.updateApplicationContext(context)
            lastSyncDate = Date()
        } catch {
            #if DEBUG
            NSLog("Failed to sync to watch: \(error.localizedDescription)")
            #endif
        }
    }

    func notifySessionStarted(startDate: Date) {
        guard let session, session.isReachable else {
            syncToWatch()
            return
        }

        let message: [String: Any] = [
            "action": "sessionStarted",
            "startDate": startDate.timeIntervalSince1970
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            #if DEBUG
            NSLog("Failed to notify session start: \(error.localizedDescription)")
            #endif
        }
    }

    func notifySessionEnded() {
        guard let session, session.isReachable else {
            syncToWatch()
            return
        }

        let message: [String: Any] = [
            "action": "sessionEnded"
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            #if DEBUG
            NSLog("Failed to notify session end: \(error.localizedDescription)")
            #endif
        }
    }
}

// MARK: - WCSessionDelegate

extension IOSWatchConnectivityService: WCSessionDelegate {
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Re-activate session
        session.activate()
    }

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            if activationState == .activated {
                syncToWatch()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isWatchReachable = session.isReachable
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            handleReceivedMessage(message, replyHandler: replyHandler)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any]
    ) {
        Task { @MainActor in
            handleReceivedMessage(message, replyHandler: nil)
        }
    }

    @MainActor
    private func handleReceivedMessage(
        _ message: [String: Any],
        replyHandler: (([String: Any]) -> Void)?
    ) {
        guard let action = message["action"] as? String else {
            replyHandler?([:])
            return
        }

        guard let store = fastingStore else {
            replyHandler?([:])
            return
        }

        switch action {
        case "startFast":
            if store.activeSession == nil {
                store.startFast()
            }
            replyHandler?(["success": true])

        case "endFast":
            if store.activeSession != nil {
                store.endFast()
            }
            replyHandler?(["success": true])

        case "requestSync":
            var reply: [String: Any] = [
                "streak": store.streakCount
            ]

            if let activeSession = store.activeSession {
                reply["activeSession"] = [
                    "startDate": activeSession.startDate.timeIntervalSince1970,
                    "note": activeSession.note
                ]
            }

            reply["thresholds"] = [
                "postMealEnd": store.thresholds.postMealEndHours,
                "earlyFastingEnd": store.thresholds.earlyFastingEndHours,
                "fatBurningEnd": store.thresholds.fatBurningEndHours
            ]

            replyHandler?(reply)

        default:
            replyHandler?([:])
        }
    }
}
