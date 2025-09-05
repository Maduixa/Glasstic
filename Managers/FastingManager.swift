import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif
import Combine
import UIKit

// MARK: - Fasting Manager
class FastingManager: ObservableObject {
    // Using a shared UserDefaults suite for App Group data sharing
    private let sharedDefaults: UserDefaults

    @Published var fastingState: FastingState = .idle {
        didSet {
            sharedDefaults.set(fastingState.rawValue, forKey: "fastingState")
            sendContextToWatch()
        }
    }
    @Published var elapsedTime: TimeInterval = 0 {
        didSet { sendContextToWatch() }
    }

    private var fastingStartDate: Double = 0 {
        didSet { sharedDefaults.set(fastingStartDate, forKey: "fastingStartDate") }
    }
    private var fastingGoal: TimeInterval = 0 {
        didSet { sharedDefaults.set(fastingGoal, forKey: "fastingGoal") }
    }

    private var timer: Timer?
    private let connectivityManager = WatchConnectivityManager.shared
    #if canImport(ActivityKit)
    private var currentActivity: Activity<FastingActivityAttributes>?
    #else
    private var currentActivity: Any?
    #endif

    init() {
        let suiteName = "group.com.maduixa.Glasstic"
        if let defaults = UserDefaults(suiteName: suiteName) {
            self.sharedDefaults = defaults
        } else {
            print("[FastingManager] App Group \(suiteName) not found. Falling back to standard UserDefaults.")
            self.sharedDefaults = .standard
        }

        self.fastingState = FastingState(rawValue: sharedDefaults.string(forKey: "fastingState") ?? "idle") ?? .idle
        self.fastingStartDate = sharedDefaults.double(forKey: "fastingStartDate")
        self.fastingGoal = sharedDefaults.double(forKey: "fastingGoal")

        if fastingState == .fasting {
            let startDate = Date(timeIntervalSince1970: fastingStartDate)
            self.elapsedTime = Date().timeIntervalSince(startDate)
            startTimer()
        }

        NotificationManager.shared.requestAuthorization()
        HealthKitManager.shared.requestAuthorization { _, _ in }
        sendContextToWatch() // Initial sync
    }

    func startFasting(goal: TimeInterval) {
        let startDate = Date()
        fastingStartDate = startDate.timeIntervalSince1970
        fastingState = .fasting
        fastingGoal = goal
        elapsedTime = 0
        startTimer()

        // Schedule AI-generated notification
        NotificationManager.shared.scheduleAINotification(for: goal)

        // Start Live Activity
        #if canImport(ActivityKit)
        let attributes = FastingActivityAttributes(fastingGoal: goal)
        let initialState = FastingActivityAttributes.ContentState(elapsedTime: 0, currentZoneName: "Anabolic", progress: 0)

        do {
            currentActivity = try Activity<FastingActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            print("Live Activity started.")
        } catch (let error) {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
        #endif
    }

    func endFasting() {
        if fastingStartDate > 0 {
            let startDate = Date(timeIntervalSince1970: fastingStartDate)
            let endDate = Date()
            HealthKitManager.shared.saveFast(startDate: startDate, endDate: endDate) { _, _ in }
            GamificationManager.shared.processCompletedFast(startDate: startDate, endDate: endDate)
        }

        fastingState = .idle
        timer?.invalidate()
        timer = nil
        fastingStartDate = 0
        fastingGoal = 0

        // End Live Activity
        #if canImport(ActivityKit)
        Task {
            let finalState = FastingActivityAttributes.ContentState(elapsedTime: elapsedTime, currentZoneName: "Ended", progress: 1.0)
            await (currentActivity as? Activity<FastingActivityAttributes>)?.end(using: finalState, dismissalPolicy: .immediate)
            print("Live Activity ended.")
        }
        #endif
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, self.fastingState == .fasting else { return }
            let startDate = Date(timeIntervalSince1970: self.fastingStartDate)
            self.elapsedTime = Date().timeIntervalSince(startDate)

            if Int(self.elapsedTime) % 30 == 0 { self.updateLiveActivity() }

            // Remove auto-end behavior - let user continue past goal
            // if self.elapsedTime >= self.fastingGoal { self.endFasting() }
        }
    }

    private func updateLiveActivity() {
        #if canImport(ActivityKit)
        Task {
            let currentZone = FastingZone.allZones.filter { elapsedTime >= $0.duration }.last ?? .anabolic
            let progress = fastingGoal > 0 ? elapsedTime / fastingGoal : 0
            let updatedState = FastingActivityAttributes.ContentState(elapsedTime: elapsedTime, currentZoneName: currentZone.name, progress: min(progress, 1.0))
            await (currentActivity as? Activity<FastingActivityAttributes>)?.update(using: updatedState)
        }
        #endif
    }

    private func sendContextToWatch() {
        let context: [String: Any] = [
            "fastingState": fastingState.rawValue,
            "fastingStartDate": fastingStartDate,
            "fastingGoal": fastingGoal
        ]
        connectivityManager.sendContext(context)
    }

    func getFastingGoal() -> TimeInterval {
        return fastingGoal
    }

    func getStartDate() -> Date {
        return Date(timeIntervalSince1970: fastingStartDate)
    }

    func updateStartTime(to newStartTime: Date) {
        fastingStartDate = newStartTime.timeIntervalSince1970

        // Recalculate elapsed time
        self.elapsedTime = Date().timeIntervalSince(newStartTime)

        // Update live activity and watch
        updateLiveActivity()
        sendContextToWatch()
    }
}

