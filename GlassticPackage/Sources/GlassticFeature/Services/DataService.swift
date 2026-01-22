import SwiftData
import Foundation

@MainActor
public final class DataService {
    public static let shared = DataService()

    public let modelContainer: ModelContainer
    private let modelContext: ModelContext

    private init() {
        let schema = Schema([FastingSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - Session Management

    public func fetchActiveFast() -> FastingSession? {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    public func startFast(
        targetDuration: TimeInterval = 16 * 3600,
        protocol fastingProtocol: FastingProtocol = .sixteenEight
    ) -> FastingSession {
        let session = FastingSession(
            startDate: Date(),
            targetDuration: targetDuration,
            fastingProtocol: fastingProtocol
        )
        modelContext.insert(session)
        try? modelContext.save()
        return session
    }

    public func endFast(_ session: FastingSession) {
        session.endDate = Date()
        try? modelContext.save()
    }

    public func saveSession(_ session: FastingSession) {
        try? modelContext.save()
    }

    // MARK: - History

    public func fetchAllSessions() -> [FastingSession] {
        let descriptor = FetchDescriptor<FastingSession>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    public func fetchCompletedSessions() -> [FastingSession] {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { $0.endDate != nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    public func fetchSessions(from startDate: Date, to endDate: Date) -> [FastingSession] {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { session in
                session.startDate >= startDate && session.startDate <= endDate
            },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    public func deleteSession(_ session: FastingSession) {
        modelContext.delete(session)
        try? modelContext.save()
    }

    public func deleteAllSessions() {
        let sessions = fetchAllSessions()
        for session in sessions {
            modelContext.delete(session)
        }
        try? modelContext.save()
    }

    // MARK: - Statistics

    public func totalFastingTime() -> TimeInterval {
        fetchCompletedSessions().reduce(0) { $0 + $1.duration }
    }

    public func averageFastingDuration() -> TimeInterval {
        let sessions = fetchCompletedSessions()
        guard !sessions.isEmpty else { return 0 }
        return totalFastingTime() / Double(sessions.count)
    }

    public func longestFast() -> FastingSession? {
        fetchCompletedSessions().max { $0.duration < $1.duration }
    }

    public func currentStreak() -> Int {
        let sessions = fetchCompletedSessions()
        guard !sessions.isEmpty else { return 0 }

        var streak = 0
        var currentDate = Calendar.current.startOfDay(for: Date())

        for session in sessions {
            let sessionDate = Calendar.current.startOfDay(for: session.startDate)
            if sessionDate == currentDate || sessionDate == Calendar.current.date(byAdding: .day, value: -1, to: currentDate) {
                streak += 1
                currentDate = sessionDate
            } else {
                break
            }
        }

        return streak
    }

    public func sessionsThisWeek() -> [FastingSession] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        return fetchSessions(from: weekStart, to: Date())
    }

    public func sessionsThisMonth() -> [FastingSession] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: Date())) else {
            return []
        }
        return fetchSessions(from: monthStart, to: Date())
    }
}
