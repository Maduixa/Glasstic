import WatchConnectivity
import Foundation

// Target: watchOS
@MainActor
final class WatchWCSession: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchWCSession()

    @Published var stepsFromPhone: Int?

    private override init() { super.init() }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func requestSteps() {
        let session = WCSession.default
        guard session.isReachable else { return }

        session.sendMessage(["kind": "requestSteps", "schemaVersion": 1], replyHandler: { [weak self] reply in
            let steps = reply["steps"] as? Int
            Task { @MainActor in self?.stepsFromPhone = steps }
        }, errorHandler: { _ in })
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}
