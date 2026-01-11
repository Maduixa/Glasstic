import Foundation
import SwiftData
@testable import Glasstic

@MainActor
final class MockDataService {
    private var sessions: [FastingSessionData] = []
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockError", code: 1)

    // Track method calls for verification
    var insertCallCount = 0
    var deleteCallCount = 0
    var saveCallCount = 0
    var fetchAllCallCount = 0

    func reset() {
        sessions = []
        shouldThrowError = false
        insertCallCount = 0
        deleteCallCount = 0
        saveCallCount = 0
        fetchAllCallCount = 0
    }

    func fetchAllSessions() throws -> [FastingSessionData] {
        fetchAllCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        return sessions.sorted { $0.startDate > $1.startDate }
    }

    func fetchActiveSessions() throws -> [FastingSessionData] {
        if shouldThrowError {
            throw errorToThrow
        }
        return sessions.filter { $0.endDate == nil }.sorted { $0.startDate > $1.startDate }
    }

    func fetchSession(withID id: UUID) throws -> FastingSessionData? {
        if shouldThrowError {
            throw errorToThrow
        }
        return sessions.first { $0.id == id }
    }

    func insert(_ session: FastingSessionData) {
        insertCallCount += 1
        sessions.append(session)
    }

    func delete(_ session: FastingSessionData) {
        deleteCallCount += 1
        sessions.removeAll { $0.id == session.id }
    }

    func save() {
        saveCallCount += 1
        // Mock save - no-op
    }

    func streakCount() throws -> Int {
        if shouldThrowError {
            throw errorToThrow
        }

        let completedSessions = sessions.filter { $0.isCompleted }.sorted { $0.startDate > $1.startDate }
        guard !completedSessions.isEmpty else { return 0 }

        let calendar = Calendar.current
        var streak = 0
        var dayCursor = calendar.startOfDay(for: Date())

        while true {
            let hasCompletedFast = completedSessions.contains { session in
                calendar.isDate(session.startDate, inSameDayAs: dayCursor)
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
        if shouldThrowError {
            throw errorToThrow
        }

        let calendar = Calendar.current
        return sessions.first { calendar.isDate($0.startDate, inSameDayAs: day) }
    }
}
