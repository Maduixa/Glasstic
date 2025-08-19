
import Foundation
import WatchConnectivity

// This class is designed to be a singleton, shared between the iOS and watchOS targets.
class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var context: [String: Any] = [:]

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle session becoming inactive
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // Reactivate the session if needed
        WCSession.default.activate()
    }
    #endif

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        DispatchQueue.main.async {
            self.context = applicationContext
        }
    }

    func sendContext(_ context: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("WCSession is not reachable.")
            return
        }
        do {
            try WCSession.default.updateApplicationContext(context)
            print("Sent context to watch: \(context)")
        } catch {
            print("Error sending context: \(error.localizedDescription)")
        }
    }
}
