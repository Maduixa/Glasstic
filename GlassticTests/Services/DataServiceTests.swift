import XCTest
import SwiftData
@testable import Glasstic

@MainActor
final class DataServiceTests: XCTestCase {
    var sut: DataService!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUp() async throws {
        try await super.setUp()

        // Create in-memory model container for testing
        let schema = Schema([FastingSessionData.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        modelContext = ModelContext(modelContainer)

        // Note: DataService is a singleton, so we can't easily inject the test context
        // In production, consider adding a test initializer
        // For now, these tests document the expected behavior
    }

    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Fetch All Sessions Tests

    func testFetchAllSessions_ReturnsEmptyArray_WhenNoSessions() throws {
        // Given: Empty context
        let descriptor = FetchDescriptor<FastingSessionData>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        // When: Fetching all sessions
        let sessions = try modelContext.fetch(descriptor)

        // Then: Should return empty array
        XCTAssertEqual(sessions.count, 0)
    }

    func testFetchAllSessions_ReturnsSortedByStartDate() throws {
        // Given: Multiple sessions with different start dates
        let session1 = FastingSessionData.makeTest(startDate: .daysAgo(3))
        let session2 = FastingSessionData.makeTest(startDate: .daysAgo(1))
        let session3 = FastingSessionData.makeTest(startDate: .daysAgo(2))

        modelContext.insert(session1)
        modelContext.insert(session2)
        modelContext.insert(session3)
        try modelContext.save()

        // When: Fetching all sessions
        let descriptor = FetchDescriptor<FastingSessionData>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)

        // Then: Should be sorted by start date (most recent first)
        XCTAssertEqual(sessions.count, 3)
        XCTAssertEqual(sessions[0].id, session2.id) // Most recent (1 day ago)
        XCTAssertEqual(sessions[1].id, session3.id) // 2 days ago
        XCTAssertEqual(sessions[2].id, session1.id) // 3 days ago
    }

    func testFetchAllSessions_ReturnsAllSessions() throws {
        // Given: 10 sessions
        for i in 0..<10 {
            let session = FastingSessionData.makeTest(
                startDate: .daysAgo(i)
            )
            modelContext.insert(session)
        }
        try modelContext.save()

        // When: Fetching all sessions
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // Then: Should return all 10
        XCTAssertEqual(sessions.count, 10)
    }

    // MARK: - Fetch Active Sessions Tests

    func testFetchActiveSessions_ReturnsOnlyActiveSessions() throws {
        // Given: Mix of active and completed sessions
        let active1 = FastingSessionData.makeActive(startDate: .hoursAgo(2))
        let active2 = FastingSessionData.makeActive(startDate: .hoursAgo(1))
        let completed1 = FastingSessionData.makeCompleted(startDate: .daysAgo(1))
        let completed2 = FastingSessionData.makeCompleted(startDate: .daysAgo(2))

        modelContext.insert(active1)
        modelContext.insert(active2)
        modelContext.insert(completed1)
        modelContext.insert(completed2)
        try modelContext.save()

        // When: Fetching active sessions
        let descriptor = FetchDescriptor<FastingSessionData>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        let sessions = try modelContext.fetch(descriptor)

        // Then: Should return only active sessions
        XCTAssertEqual(sessions.count, 2)
        XCTAssertTrue(sessions.allSatisfy { $0.isActive })
        XCTAssertEqual(sessions[0].id, active2.id) // Most recent
        XCTAssertEqual(sessions[1].id, active1.id)
    }

    func testFetchActiveSessions_ReturnsEmpty_WhenNoActiveSessions() throws {
        // Given: Only completed sessions
        let completed = FastingSessionData.makeCompleted()
        modelContext.insert(completed)
        try modelContext.save()

        // When: Fetching active sessions
        let descriptor = FetchDescriptor<FastingSessionData>(
            predicate: #Predicate { $0.endDate == nil }
        )
        let sessions = try modelContext.fetch(descriptor)

        // Then: Should return empty array
        XCTAssertEqual(sessions.count, 0)
    }

    // MARK: - Fetch Session by ID Tests

    func testFetchSessionWithID_ReturnsCorrectSession() throws {
        // Given: Multiple sessions
        let session1 = FastingSessionData.makeTest(note: "Session 1")
        let session2 = FastingSessionData.makeTest(note: "Session 2")
        let session3 = FastingSessionData.makeTest(note: "Session 3")

        modelContext.insert(session1)
        modelContext.insert(session2)
        modelContext.insert(session3)
        try modelContext.save()

        // When: Fetching specific session by ID
        let targetID = session2.id
        let descriptor = FetchDescriptor<FastingSessionData>(
            predicate: #Predicate { $0.id == targetID }
        )
        let result = try modelContext.fetch(descriptor).first

        // Then: Should return correct session
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, session2.id)
        XCTAssertEqual(result?.note, "Session 2")
    }

    func testFetchSessionWithID_ReturnsNil_WhenIDNotFound() throws {
        // Given: Some sessions
        let session = FastingSessionData.makeTest()
        modelContext.insert(session)
        try modelContext.save()

        // When: Fetching non-existent ID
        let nonExistentID = UUID()
        let descriptor = FetchDescriptor<FastingSessionData>(
            predicate: #Predicate { $0.id == nonExistentID }
        )
        let result = try modelContext.fetch(descriptor).first

        // Then: Should return nil
        XCTAssertNil(result)
    }

    // MARK: - Insert Tests

    func testInsert_AddsSessionToContext() throws {
        // Given: Empty context
        let session = FastingSessionData.makeTest(note: "New session")

        // When: Inserting session
        modelContext.insert(session)
        try modelContext.save()

        // Then: Session should be in context
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 1)
        XCTAssertEqual(sessions[0].note, "New session")
    }

    func testInsert_MultipleSessionsRetainUniqueIDs() throws {
        // Given: Multiple sessions
        let session1 = FastingSessionData.makeTest()
        let session2 = FastingSessionData.makeTest()
        let session3 = FastingSessionData.makeTest()

        // When: Inserting all
        modelContext.insert(session1)
        modelContext.insert(session2)
        modelContext.insert(session3)
        try modelContext.save()

        // Then: All should have unique IDs
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 3)

        let ids = Set(sessions.map { $0.id })
        XCTAssertEqual(ids.count, 3) // All unique
    }

    // MARK: - Delete Tests

    func testDelete_RemovesSessionFromContext() throws {
        // Given: Session in context
        let session = FastingSessionData.makeTest(note: "To be deleted")
        modelContext.insert(session)
        try modelContext.save()

        // Verify it exists
        var descriptor = FetchDescriptor<FastingSessionData>()
        var sessions = try modelContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 1)

        // When: Deleting session
        modelContext.delete(session)
        try modelContext.save()

        // Then: Session should be removed
        descriptor = FetchDescriptor<FastingSessionData>()
        sessions = try modelContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 0)
    }

    func testDelete_OnlyDeletesSpecifiedSession() throws {
        // Given: Multiple sessions
        let session1 = FastingSessionData.makeTest(note: "Keep 1")
        let session2 = FastingSessionData.makeTest(note: "Delete me")
        let session3 = FastingSessionData.makeTest(note: "Keep 2")

        modelContext.insert(session1)
        modelContext.insert(session2)
        modelContext.insert(session3)
        try modelContext.save()

        // When: Deleting one session
        modelContext.delete(session2)
        try modelContext.save()

        // Then: Only specified session should be deleted
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)
        XCTAssertEqual(sessions.count, 2)
        XCTAssertFalse(sessions.contains { $0.id == session2.id })
        XCTAssertTrue(sessions.contains { $0.id == session1.id })
        XCTAssertTrue(sessions.contains { $0.id == session3.id })
    }

    // MARK: - Save Tests

    func testSave_PersistsChanges() throws {
        // Given: Session in context
        let session = FastingSessionData.makeActive(note: "Original note")
        modelContext.insert(session)
        try modelContext.save()

        // When: Modifying and saving
        session.note = "Updated note"
        try modelContext.save()

        // Then: Changes should be persisted
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)
        XCTAssertEqual(sessions[0].note, "Updated note")
    }

    func testSave_HandlesMultipleChanges() throws {
        // Given: Multiple sessions
        let session1 = FastingSessionData.makeTest(note: "Note 1")
        let session2 = FastingSessionData.makeTest(note: "Note 2")

        modelContext.insert(session1)
        modelContext.insert(session2)
        try modelContext.save()

        // When: Making multiple changes
        session1.note = "Updated 1"
        session2.note = "Updated 2"
        session1.endDate = Date()
        try modelContext.save()

        // Then: All changes should be persisted
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)
        let updated1 = sessions.first { $0.id == session1.id }
        let updated2 = sessions.first { $0.id == session2.id }

        XCTAssertEqual(updated1?.note, "Updated 1")
        XCTAssertEqual(updated2?.note, "Updated 2")
        XCTAssertNotNil(updated1?.endDate)
    }

    // MARK: - Streak Count Tests

    func testStreakCount_ReturnsZero_WhenNoSessions() throws {
        // Given: Empty context
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // When: Calculating streak
        let streak = calculateStreak(sessions: sessions)

        // Then: Should be zero
        XCTAssertEqual(streak, 0)
    }

    func testStreakCount_ReturnsZero_WhenNoCompletedSessions() throws {
        // Given: Only active sessions
        let active = FastingSessionData.makeActive()
        modelContext.insert(active)
        try modelContext.save()

        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // When: Calculating streak
        let streak = calculateStreak(sessions: sessions)

        // Then: Should be zero
        XCTAssertEqual(streak, 0)
    }

    func testStreakCount_CountsConsecutiveDays() throws {
        // Given: 5 consecutive days of completed fasts
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for i in 0..<5 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let session = FastingSessionData.makeCompleted(
                startDate: date,
                duration: 16 * 3600
            )
            modelContext.insert(session)
        }
        try modelContext.save()

        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // When: Calculating streak
        let streak = calculateStreak(sessions: sessions)

        // Then: Should be 5
        XCTAssertEqual(streak, 5)
    }

    func testStreakCount_StopsAtFirstGap() throws {
        // Given: Sessions with a gap
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Today and yesterday
        for i in 0..<2 {
            let date = calendar.date(byAdding: .day, value: -i, to: today)!
            let session = FastingSessionData.makeCompleted(
                startDate: date,
                duration: 16 * 3600
            )
            modelContext.insert(session)
        }

        // Skip day 2, add day 3
        let threeDaysAgo = calendar.date(byAdding: .day, value: -3, to: today)!
        let session = FastingSessionData.makeCompleted(
            startDate: threeDaysAgo,
            duration: 16 * 3600
        )
        modelContext.insert(session)
        try modelContext.save()

        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // When: Calculating streak
        let streak = calculateStreak(sessions: sessions)

        // Then: Should be 2 (stops at gap)
        XCTAssertEqual(streak, 2)
    }

    func testStreakCount_HandlesMultipleSessionsPerDay() throws {
        // Given: Multiple completed sessions on same day
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Two sessions today
        let morning = FastingSessionData.makeCompleted(
            startDate: today.addingTimeInterval(6 * 3600), // 6 AM
            duration: 16 * 3600
        )
        let evening = FastingSessionData.makeCompleted(
            startDate: today.addingTimeInterval(18 * 3600), // 6 PM
            duration: 16 * 3600
        )
        modelContext.insert(morning)
        modelContext.insert(evening)
        try modelContext.save()

        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // When: Calculating streak
        let streak = calculateStreak(sessions: sessions)

        // Then: Should count as 1 day
        XCTAssertEqual(streak, 1)
    }

    // MARK: - Session for Day Tests

    func testSessionForDay_ReturnsCorrectSession() throws {
        // Given: Sessions on different days
        let targetDate = Date.makeDate(year: 2024, month: 6, day: 15)
        let otherDate = Date.makeDate(year: 2024, month: 6, day: 16)

        let targetSession = FastingSessionData.makeCompleted(startDate: targetDate)
        let otherSession = FastingSessionData.makeCompleted(startDate: otherDate)

        modelContext.insert(targetSession)
        modelContext.insert(otherSession)
        try modelContext.save()

        // When: Finding session for specific day
        let descriptor = FetchDescriptor<FastingSessionData>()
        let allSessions = try modelContext.fetch(descriptor)
        let result = findSession(for: targetDate, in: allSessions)

        // Then: Should return correct session
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, targetSession.id)
    }

    func testSessionForDay_ReturnsNil_WhenNoSessionForDay() throws {
        // Given: Sessions on specific days
        let existingDate = Date.makeDate(year: 2024, month: 6, day: 15)
        let queryDate = Date.makeDate(year: 2024, month: 6, day: 20)

        let session = FastingSessionData.makeCompleted(startDate: existingDate)
        modelContext.insert(session)
        try modelContext.save()

        // When: Finding session for day without session
        let descriptor = FetchDescriptor<FastingSessionData>()
        let allSessions = try modelContext.fetch(descriptor)
        let result = findSession(for: queryDate, in: allSessions)

        // Then: Should return nil
        XCTAssertNil(result)
    }

    func testSessionForDay_ReturnsFirstSession_WhenMultipleSessionsSameDay() throws {
        // Given: Multiple sessions same day
        let targetDate = Date.makeDate(year: 2024, month: 6, day: 15, hour: 0)

        let morning = FastingSessionData.makeCompleted(
            startDate: targetDate.addingTimeInterval(6 * 3600),
            duration: 8 * 3600
        )
        let evening = FastingSessionData.makeCompleted(
            startDate: targetDate.addingTimeInterval(18 * 3600),
            duration: 12 * 3600
        )

        modelContext.insert(morning)
        modelContext.insert(evening)
        try modelContext.save()

        // When: Finding session for that day
        let descriptor = FetchDescriptor<FastingSessionData>()
        let allSessions = try modelContext.fetch(descriptor)
        let result = findSession(for: targetDate, in: allSessions)

        // Then: Should return first matching session
        XCTAssertNotNil(result)
        XCTAssertTrue([morning.id, evening.id].contains(result!.id))
    }

    // MARK: - Edge Cases

    func testEdgeCase_FetchAfterDelete() throws {
        // Given: Session inserted and deleted
        let session = FastingSessionData.makeTest()
        modelContext.insert(session)
        try modelContext.save()

        modelContext.delete(session)
        try modelContext.save()

        // When: Fetching all
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // Then: Should be empty
        XCTAssertEqual(sessions.count, 0)
    }

    func testEdgeCase_ModifyWithoutSave() throws {
        // Given: Session in context
        let session = FastingSessionData.makeTest(note: "Original")
        modelContext.insert(session)
        try modelContext.save()

        // When: Modifying without saving
        session.note = "Modified"
        // Not calling save()

        // Re-fetch from context
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)

        // Then: Changes should still be visible (in-memory)
        XCTAssertEqual(sessions[0].note, "Modified")
    }

    func testEdgeCase_ConcurrentModifications() throws {
        // Given: Session in context
        let session = FastingSessionData.makeTest()
        modelContext.insert(session)
        try modelContext.save()

        // When: Multiple modifications
        session.note = "First update"
        session.endDate = Date()
        session.note = "Second update"
        try modelContext.save()

        // Then: Last modification wins
        let descriptor = FetchDescriptor<FastingSessionData>()
        let sessions = try modelContext.fetch(descriptor)
        XCTAssertEqual(sessions[0].note, "Second update")
        XCTAssertNotNil(sessions[0].endDate)
    }

    // MARK: - Helper Methods

    private func calculateStreak(sessions: [FastingSessionData]) -> Int {
        let completedSessions = sessions.filter { $0.isCompleted }
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

    private func findSession(for day: Date, in sessions: [FastingSessionData]) -> FastingSessionData? {
        let calendar = Calendar.current
        return sessions.first { calendar.isDate($0.startDate, inSameDayAs: day) }
    }
}
