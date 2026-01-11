import Foundation
import SwiftData

@MainActor
final class DataService {
    static let shared = DataService()

    private(set) var modelContainer: ModelContainer
    private(set) var modelContext: ModelContext

    private init() {
        let schema = Schema([
            FastingSessionData.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    // MARK: - CRUD Operations

    func fetchAllSessions() throws -> [FastingSessionData] {
        let descriptor = FetchDescriptor<FastingSessionData>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchActiveSessions() throws -> [FastingSessionData] {
        let descriptor = FetchDescriptor<FastingSessionData>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchSession(withID id: UUID) throws -> FastingSessionData? {
        let descriptor = FetchDescriptor<FastingSessionData>(
            predicate: #Predicate { $0.id == id }
        )
        return try modelContext.fetch(descriptor).first
    }

    func insert(_ session: FastingSessionData) {
        modelContext.insert(session)
        save()
    }

    func delete(_ session: FastingSessionData) {
        modelContext.delete(session)
        save()
    }

    func save() {
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            NSLog("Failed to save context: \(error.localizedDescription)")
            #endif
        }
    }

    // MARK: - Query Helpers

    func streakCount() throws -> Int {
        let sessions = try fetchAllSessions()
        guard !sessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var dayCursor = calendar.startOfDay(for: Date())

        while true {
            let hasCompletedFast = sessions.contains { session in
                session.isCompleted && calendar.isDate(session.startDate, inSameDayAs: dayCursor)
            }

            if hasCompletedFast {
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

    func session(for day: Date) throws -> FastingSessionData? {
        let calendar = Calendar.current
        let sessions = try fetchAllSessions()
        return sessions.first { calendar.isDate($0.startDate, inSameDayAs: day) }
    }
}
