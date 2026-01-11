import Combine
import SwiftUI
import Observation

@Observable
@MainActor
final class FastingStore {
    private(set) var sessions: [FastingSessionData] = []
    var thresholds: FastingThresholds {
        didSet {
            UserDefaults.standard.set(try? JSONEncoder().encode(thresholds), forKey: "thresholds")
        }
    }
    var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.id, forKey: "selectedThemeID")
        }
    }
    private(set) var activeSession: FastingSessionData?
    private(set) var elapsed: TimeInterval = 0
    private(set) var activeZone: FastingZone = .postMeal
    private(set) var activeNudge: String = ""

    private let dataService = DataService.shared
    private let healthKitService = HealthKitService.shared
    private let notificationService = NotificationService.shared
    private let watchConnectivity = IOSWatchConnectivityService.shared
    private var timer: AnyCancellable?
    private var zoneFeedback = PassthroughSubject<FastingZone, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Load thresholds from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "thresholds"),
           let savedThresholds = try? JSONDecoder().decode(FastingThresholds.self, from: data) {
            self.thresholds = savedThresholds
        } else {
            self.thresholds = .default
        }

        // Load selected theme
        if let themeIDString = UserDefaults.standard.string(forKey: "selectedThemeID"),
           let themeID = UUID(uuidString: themeIDString),
           let theme = AppTheme.allThemes.first(where: { $0.id == themeID }) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = AppTheme.allThemes.first ?? AppTheme.allThemes[0]
        }

        // Load sessions from SwiftData
        do {
            self.sessions = try dataService.fetchAllSessions()
            self.activeSession = try dataService.fetchActiveSessions().first
        } catch {
            #if DEBUG
            NSLog("Failed to load sessions: \(error.localizedDescription)")
            #endif
            self.sessions = []
            self.activeSession = nil
        }

        observeZoneChanges()
        resumeTimerIfNeeded()
        watchConnectivity.configure(with: self)
    }

    func startFast(note: String = "") {
        guard activeSession == nil else { return }
        let now = Date()
        let session = FastingSessionData(startDate: now, note: note)
        activeSession = session
        sessions.insert(session, at: 0)
        dataService.insert(session)
        elapsed = 0
        recalculateZone()
        activeNudge = nudge(for: activeZone)
        startTimer()
        watchConnectivity.notifySessionStarted(startDate: now)
    }

    func endFast(note: String? = nil) {
        guard let session = activeSession else { return }
        session.endDate = Date()
        if let note {
            session.note = note
        }
        dataService.save()

        // Save to HealthKit
        Task {
            try? await healthKitService.saveFastingWorkout(
                startDate: session.startDate,
                endDate: session.endDate ?? Date(),
                duration: session.duration
            )

            // Check for streak milestone
            let streak = streakCount
            try? await notificationService.notifyStreakMilestone(streak: streak)
        }

        refreshSessions()
        activeSession = nil
        stopTimer()
        elapsed = 0
        activeZone = thresholds.zone(for: 0)
        activeNudge = ""
        watchConnectivity.notifySessionEnded()
    }

    func delete(_ session: FastingSessionData) {
        if session.id == activeSession?.id {
            stopTimer()
            activeSession = nil
            elapsed = 0
        }
        dataService.delete(session)
        refreshSessions()
    }

    func updateSession(_ session: FastingSessionData) {
        dataService.save()
        refreshSessions()
        if session.id == activeSession?.id {
            activeSession = session
        }
    }

    func updateTheme(to theme: AppTheme) {
        selectedTheme = theme
    }

    func updateThresholds(_ thresholds: FastingThresholds) {
        self.thresholds = thresholds.clamped()
        recalculateZone()
        watchConnectivity.syncToWatch()
    }

    var streakCount: Int {
        do {
            return try dataService.streakCount()
        } catch {
            return 0
        }
    }

    func session(for day: Date) -> FastingSessionData? {
        do {
            return try dataService.session(for: day)
        } catch {
            return nil
        }
    }

    func nudge(for zone: FastingZone) -> String {
        zone.defaultNudges.randomElement() ?? ""
    }

    func requestPermissions() async {
        do {
            try await healthKitService.requestAuthorization()
            try await notificationService.requestAuthorization()
            notificationService.setupCategories()
        } catch {
            #if DEBUG
            NSLog("Permission request failed: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - AI Analysis Methods

    func canAnalyzeAIData() -> Bool {
        do {
            return try AIAnalysisService.shared.canAnalyze()
        } catch {
            return false
        }
    }

    func getAIPrediction() throws -> AIAnalysisService.FastingPrediction {
        try AIAnalysisService.shared.getPrediction()
    }

    func getAIInsights() throws -> FastingInsights {
        try AIAnalysisService.shared.getInsights()
    }

    private func refreshSessions() {
        do {
            sessions = try dataService.fetchAllSessions()
        } catch {
            #if DEBUG
            NSLog("Failed to refresh sessions: \(error.localizedDescription)")
            #endif
        }
    }

    private func observeZoneChanges() {
        zoneFeedback
            .removeDuplicates()
            .sink { [weak self] (zone: FastingZone) in
                guard let self else { return }
                activeNudge = nudge(for: zone)
            }
            .store(in: &cancellables)
    }

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

    private func resumeTimerIfNeeded() {
        guard let session = activeSession else { return }
        elapsed = session.actualEndDate.timeIntervalSince(session.startDate)
        recalculateZone()
        startTimer()
    }

    private func tick() {
        guard let session = activeSession else {
            stopTimer()
            return
        }
        elapsed = Date().timeIntervalSince(session.startDate)
        recalculateZone()
    }

    private func recalculateZone() {
        let newZone = thresholds.zone(for: elapsed)
        if newZone != activeZone {
            activeZone = newZone
            zoneFeedback.send(newZone)
        } else {
            activeZone = newZone
        }
    }

}
