import Combine
import SwiftUI

@MainActor
final class FastingStore: ObservableObject {
    @Published private(set) var sessions: [FastingSession]
    @Published var thresholds: FastingThresholds {
        didSet { persist() }
    }
    @Published var selectedTheme: AppTheme {
        didSet { persist() }
    }
    @Published private(set) var activeSession: FastingSession?
    @Published private(set) var elapsed: TimeInterval = 0
    @Published private(set) var activeZone: FastingZone = .postMeal
    @Published private(set) var activeNudge: String = ""

    private let persistence = JSONFileStore<PersistedAppState>(fileName: "app_state.json")
    private var timer: AnyCancellable?
    private var zoneFeedback = PassthroughSubject<FastingZone, Never>()
    private var cancellables = Set<AnyCancellable>()

    init() {
        let state = persistence.load(
            defaultValue: PersistedAppState(
                sessions: [],
                thresholds: .default,
                selectedThemeID: AppTheme.allThemes.first?.id
            )
        )
        let theme = AppTheme.allThemes.first { $0.id == state.selectedThemeID } ?? AppTheme.allThemes.first ?? AppTheme.defaultTheme
        self.sessions = state.sessions.sorted { $0.startDate > $1.startDate }
        self.thresholds = state.thresholds
        self.selectedTheme = theme
        self.activeSession = sessions.first(where: { $0.isActive })

        observeZoneChanges()
        resumeTimerIfNeeded()
    }

    func startFast(note: String = "") {
        guard activeSession == nil else { return }
        let now = Date()
        let session = FastingSession(startDate: now, note: note)
        activeSession = session
        sessions.insert(session, at: 0)
        elapsed = 0
        recalculateZone()
        activeNudge = nudge(for: activeZone)
        persist()
        startTimer()
    }

    func endFast(note: String? = nil) {
        guard var session = activeSession else { return }
        let endDate = Date()
        session.endDate = endDate
        if let note {
            session.note = note
        }
        replace(session)
        activeSession = nil
        stopTimer()
        elapsed = 0
        activeZone = thresholds.zone(for: 0)
        activeNudge = ""
        persist()
    }

    func delete(_ session: FastingSession) {
        if session.id == activeSession?.id {
            stopTimer()
            activeSession = nil
            elapsed = 0
        }
        sessions.removeAll { $0.id == session.id }
        persist()
    }

    func updateSession(_ session: FastingSession) {
        replace(session)
        persist()
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
    }

    var streakCount: Int {
        guard !sessions.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var dayCursor = calendar.startOfDay(for: Date())

        while true {
            if sessions.contains(where: { $0.isCompleted && calendar.isDate($0.startDate, inSameDayAs: dayCursor) }) {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: dayCursor) else {
                    break
                }
                dayCursor = previous
            } else {
                break
            }
        }
        return streak
    }

    func session(for day: Date) -> FastingSession? {
        let calendar = Calendar.current
        return sessions.first { calendar.isDate($0.startDate, inSameDayAs: day) }
    }

    func nudge(for zone: FastingZone) -> String {
        zone.defaultNudges.randomElement() ?? ""
    }

    private func replace(_ session: FastingSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else {
            sessions.append(session)
        }
        sessions.sort { $0.startDate > $1.startDate }
    }

    private func observeZoneChanges() {
        zoneFeedback
            .removeDuplicates()
            .sink { [weak self] zone in
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

    private func persist() {
        let state = PersistedAppState(
            sessions: sessions,
            thresholds: thresholds,
            selectedThemeID: selectedTheme.id
        )
        persistence.save(state)
    }
}
