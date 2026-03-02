import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private(set) var isAuthorized = false

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        isAuthorized = try await center.requestAuthorization(options: options)
    }

    // MARK: - Fasting Start/End Reminders

    func scheduleFastingStartReminder(at time: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Time to start fasting"
        content.body = "Ready to begin your fast? Track your progress in Glasstic."
        content.sound = .default
        content.categoryIdentifier = "FASTING_START"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "fasting-start-reminder",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    func scheduleFastingEndReminder(for duration: TimeInterval) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Fast complete!"
        content.body = "Great job! Your fast is complete. Time to break your fast mindfully."
        content.sound = .default
        content.categoryIdentifier = "FASTING_END"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: duration, repeats: false)

        let request = UNNotificationRequest(
            identifier: "fasting-end-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Zone Transition Notifications

    func scheduleZoneTransitionNotification(
        zoneName: String,
        timeUntil: TimeInterval,
        message: String
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = "Entering \(zoneName)"
        content.body = message
        content.sound = .default
        content.categoryIdentifier = "ZONE_TRANSITION"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeUntil, repeats: false)

        let request = UNNotificationRequest(
            identifier: "zone-\(zoneName)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Streak Milestone Notifications

    func notifyStreakMilestone(streak: Int) async throws {
        guard streak > 0 && (streak % 7 == 0 || streak == 3 || streak == 5) else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "🔥 Streak Milestone!"
        content.body = "Amazing! You've maintained a \(streak)-day fasting streak. Keep it up!"
        content.sound = .default
        content.categoryIdentifier = "STREAK_MILESTONE"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "streak-\(streak)",
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Clear Notifications

    func clearAllPendingNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    func clearNotifications(withIdentifiers identifiers: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Setup Notification Categories

    func setupCategories() {
        let fastingStartCategory = UNNotificationCategory(
            identifier: "FASTING_START",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let fastingEndCategory = UNNotificationCategory(
            identifier: "FASTING_END",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let zoneTransitionCategory = UNNotificationCategory(
            identifier: "ZONE_TRANSITION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let streakCategory = UNNotificationCategory(
            identifier: "STREAK_MILESTONE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        center.setNotificationCategories([
            fastingStartCategory,
            fastingEndCategory,
            zoneTransitionCategory,
            streakCategory
        ])
    }
}
