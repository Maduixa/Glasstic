import Foundation
import UserNotifications
@testable import Glasstic

@MainActor
final class MockNotificationService {
    var isAuthorized = false
    var shouldThrowError = false
    var errorToThrow: Error = NSError(domain: "MockNotificationError", code: 1)

    // Track method calls
    var requestAuthorizationCallCount = 0
    var scheduleFastingStartReminderCallCount = 0
    var scheduleFastingEndReminderCallCount = 0
    var scheduleZoneTransitionCallCount = 0
    var notifyStreakMilestoneCallCount = 0
    var clearAllPendingNotificationsCallCount = 0
    var clearNotificationsCallCount = 0
    var setupCategoriesCallCount = 0

    // Store scheduled notifications for verification
    var scheduledFastingStartTime: Date?
    var scheduledFastingEndDuration: TimeInterval?
    var scheduledZoneTransitions: [(zoneName: String, timeUntil: TimeInterval, message: String)] = []
    var streakNotifications: [Int] = []
    var clearedIdentifiers: [[String]] = []

    func reset() {
        isAuthorized = false
        shouldThrowError = false
        requestAuthorizationCallCount = 0
        scheduleFastingStartReminderCallCount = 0
        scheduleFastingEndReminderCallCount = 0
        scheduleZoneTransitionCallCount = 0
        notifyStreakMilestoneCallCount = 0
        clearAllPendingNotificationsCallCount = 0
        clearNotificationsCallCount = 0
        setupCategoriesCallCount = 0
        scheduledFastingStartTime = nil
        scheduledFastingEndDuration = nil
        scheduledZoneTransitions = []
        streakNotifications = []
        clearedIdentifiers = []
    }

    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        isAuthorized = true
    }

    func scheduleFastingStartReminder(at time: Date) async throws {
        scheduleFastingStartReminderCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        scheduledFastingStartTime = time
    }

    func scheduleFastingEndReminder(for duration: TimeInterval) async throws {
        scheduleFastingEndReminderCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        scheduledFastingEndDuration = duration
    }

    func scheduleZoneTransitionNotification(
        zoneName: String,
        timeUntil: TimeInterval,
        message: String
    ) async throws {
        scheduleZoneTransitionCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        scheduledZoneTransitions.append((zoneName, timeUntil, message))
    }

    func notifyStreakMilestone(streak: Int) async throws {
        notifyStreakMilestoneCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        streakNotifications.append(streak)
    }

    func clearAllPendingNotifications() {
        clearAllPendingNotificationsCallCount += 1
    }

    func clearNotifications(withIdentifiers identifiers: [String]) {
        clearNotificationsCallCount += 1
        clearedIdentifiers.append(identifiers)
    }

    func setupCategories() {
        setupCategoriesCallCount += 1
    }
}
