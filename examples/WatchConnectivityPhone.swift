import WatchConnectivity

// Target: iOS
final class PhoneWCSession: NSObject, WCSessionDelegate {
    static let shared = PhoneWCSession()
    private override init() { super.init() }

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        guard let kind = message["kind"] as? String else { return }
        switch kind {
        case "requestSteps":
            // TODO: replace with real HealthKit value
            replyHandler(["kind": "replySteps", "steps": 1234, "schemaVersion": 1])
        default:
            replyHandler(["kind": "error", "message": "Unknown kind", "schemaVersion": 1])
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
}
