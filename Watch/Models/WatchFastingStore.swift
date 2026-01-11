import Foundation
import Combine
import WatchKit

@MainActor
final class WatchFastingStore: ObservableObject {
    static let shared = WatchFastingStore()

    @Published private(set) var activeSession: WatchFastingSession?
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var activeZone: FastingZone = .postMeal
    @Published private(set) var thresholds: FastingThresholds = .default
    @Published private(set) var streak: Int = 0

    private var timer: AnyCancellable?

    private init() {
        loadFromDefaults()
    }

    // MARK: - Public Methods

    func startFast(startDate: Date = Date()) {
        guard activeSession == nil else { return }

        let session = WatchFastingSession(startDate: startDate)
        activeSession = session
        elapsed = 0
        recalculateZone()
        startTimer()
        saveToDefaults()

        // Send haptic feedback
        WKInterfaceDevice.current().play(.start)
    }

    func endFast() {
        guard activeSession != nil else { return }

        activeSession = nil
        elapsed = 0
        activeZone = .postMeal
        stopTimer()
        saveToDefaults()

        // Send haptic feedback
        WKInterfaceDevice.current().play(.success)
    }

    func clearActiveSession() {
        activeSession = nil
        elapsed = 0
        activeZone = .postMeal
        stopTimer()
        saveToDefaults()
    }

    func updateFromSync(
        startDate: Date,
        endDate: Date?,
        note: String,
        thresholds: FastingThresholds,
        streak: Int
    ) {
        self.thresholds = thresholds
        self.streak = streak

        if let endDate, endDate < Date() {
            // Session already ended
            clearActiveSession()
        } else {
            // Active session or future session
            if activeSession == nil || activeSession?.startDate != startDate {
                activeSession = WatchFastingSession(startDate: startDate, note: note)
                elapsed = Date().timeIntervalSince(startDate)
                recalculateZone()
                startTimer()
            }
        }

        saveToDefaults()
    }

    var currentProgress: Double {
        guard activeSession != nil else { return 0 }
        return thresholds.progress(in: activeZone, elapsed: elapsed)
    }

    var progressPercentage: Int {
        Int(currentProgress * 100)
    }

    var elapsedHours: Int {
        Int(elapsed / 3600)
    }

    var elapsedMinutes: Int {
        Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
    }

    var timeRemaining: TimeInterval {
        guard activeSession != nil else { return 0 }

        let currentZoneEnd: Double
        switch activeZone {
        case .postMeal:
            currentZoneEnd = thresholds.postMealEndHours
        case .earlyFasting:
            currentZoneEnd = thresholds.earlyFastingEndHours
        case .fatBurning:
            currentZoneEnd = thresholds.fatBurningEndHours
        case .deepKetosis:
            return 0 // Open-ended
        }

        let currentZoneEndSeconds = currentZoneEnd * 3600
        return max(0, currentZoneEndSeconds - elapsed)
    }

    // MARK: - Private Methods

    private func startTimer() {
        timer?.cancel()
        guard activeSession != nil else { return }

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard let session = activeSession else {
            stopTimer()
            return
        }

        let previousZone = activeZone
        elapsed = Date().timeIntervalSince(session.startDate)
        recalculateZone()

        // Haptic feedback on zone change
        if activeZone != previousZone {
            WKInterfaceDevice.current().play(.notification)
        }
    }

    private func recalculateZone() {
        activeZone = thresholds.zone(for: elapsed)
    }

    // MARK: - Persistence

    private func saveToDefaults() {
        let defaults = UserDefaults.standard

        if let session = activeSession {
            defaults.set(session.startDate.timeIntervalSince1970, forKey: "activeSessionStart")
            defaults.set(session.note, forKey: "activeSessionNote")
        } else {
            defaults.removeObject(forKey: "activeSessionStart")
            defaults.removeObject(forKey: "activeSessionNote")
        }

        if let thresholdsData = try? JSONEncoder().encode(thresholds) {
            defaults.set(thresholdsData, forKey: "thresholds")
        }

        defaults.set(streak, forKey: "streak")
    }

    private func loadFromDefaults() {
        let defaults = UserDefaults.standard

        // Load thresholds
        if let thresholdsData = defaults.data(forKey: "thresholds"),
           let savedThresholds = try? JSONDecoder().decode(FastingThresholds.self, from: thresholdsData) {
            thresholds = savedThresholds
        }

        // Load streak
        streak = defaults.integer(forKey: "streak")

        // Load active session
        if let startTimestamp = defaults.object(forKey: "activeSessionStart") as? TimeInterval {
            let startDate = Date(timeIntervalSince1970: startTimestamp)
            let note = defaults.string(forKey: "activeSessionNote") ?? ""

            activeSession = WatchFastingSession(startDate: startDate, note: note)
            elapsed = Date().timeIntervalSince(startDate)
            recalculateZone()
            startTimer()
        }
    }
}

// MARK: - Watch Fasting Session

struct WatchFastingSession {
    let id: UUID
    let startDate: Date
    var note: String

    init(id: UUID = UUID(), startDate: Date, note: String = "") {
        self.id = id
        self.startDate = startDate
        self.note = note
    }
}
