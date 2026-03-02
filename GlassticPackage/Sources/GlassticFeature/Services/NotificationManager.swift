//
//  NotificationManager.swift
//  Glasstic
//
//  Manages local notifications for fasting zone transitions, goal achievements,
//  and scheduled reminders.
//

import Foundation
import UserNotifications

/// Manages all local notifications for the Glasstic fasting app.
@MainActor
public final class NotificationManager: Sendable {
    
    // MARK: - Singleton
    
    public static let shared = NotificationManager()
    
    // MARK: - Properties
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Current authorization status
    public private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Notification Identifiers
    
    private enum NotificationID {
        static let zoneTransitionPrefix = "zone_transition_"
        static let goalReached = "goal_reached"
        static let fastingReminder = "fasting_reminder"
        static let hydrationReminder = "hydration_reminder"
    }
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization
    public func requestAuthorization() async throws -> Bool {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
        
        do {
            let granted = try await notificationCenter.requestAuthorization(options: options)
            await checkAuthorizationStatus()
            return granted
        } catch {
            throw error
        }
    }
    
    /// Check current authorization status
    public func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }
    
    // MARK: - Zone Transition Notifications
    
    /// Schedule a notification for when the user will enter a new fasting zone
    public func scheduleZoneTransitionNotification(
        zone: FastingZone,
        triggerDate: Date
    ) async {
        guard authorizationStatus == .authorized else { return }
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(zone.emoji) \(zone.name)"
        content.body = zone.metabolicDescription
        content.sound = .default
        content.categoryIdentifier = "ZONE_TRANSITION"
        content.userInfo = ["zone": zone.rawValue]
        
        // Make it time-sensitive for better delivery
        content.interruptionLevel = .timeSensitive
        
        let triggerInterval = triggerDate.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(triggerInterval, 1),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.zoneTransitionPrefix)\(zone.rawValue)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[Notifications] Failed to schedule zone transition: \(error)")
        }
    }
    
    /// Schedule all upcoming zone transition notifications based on current elapsed time
    public func scheduleAllZoneNotifications(
        fastStartDate: Date,
        currentZone: FastingZone
    ) async {
        // Cancel existing zone notifications first
        await cancelZoneNotifications()
        
        // Schedule notifications for all future zones
        for zone in FastingZone.allCases where zone.rawValue > currentZone.rawValue {
            let zoneStartTime = fastStartDate.addingTimeInterval(zone.startHour * 3600)
            
            if zoneStartTime > Date() {
                await scheduleZoneTransitionNotification(zone: zone, triggerDate: zoneStartTime)
            }
        }
    }
    
    /// Cancel all zone transition notifications
    public func cancelZoneNotifications() async {
        let identifiers = FastingZone.allCases.map { "\(NotificationID.zoneTransitionPrefix)\($0.rawValue)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
    
    // MARK: - Goal Notifications
    
    /// Schedule a notification for when the user reaches their fasting goal
    public func scheduleGoalNotification(triggerDate: Date) async {
        guard authorizationStatus == .authorized else { return }
        guard triggerDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Goal Reached!"
        content.body = "Congratulations! You've completed your fasting goal. Great job staying committed!"
        content.sound = .defaultCritical
        content.categoryIdentifier = "GOAL_REACHED"
        content.interruptionLevel = .timeSensitive
        
        let triggerInterval = triggerDate.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(triggerInterval, 1),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: NotificationID.goalReached,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[Notifications] Failed to schedule goal notification: \(error)")
        }
    }
    
    /// Cancel the goal notification
    public func cancelGoalNotification() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.goalReached]
        )
    }
    
    // MARK: - Reminder Notifications
    
    /// Schedule a daily fasting reminder
    public func scheduleDailyReminder(at hour: Int, minute: Int) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time to Fast"
        content.body = "Ready to start your fasting window? Tap to begin tracking."
        content.sound = .default
        content.categoryIdentifier = "FASTING_REMINDER"
        
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: NotificationID.fastingReminder,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[Notifications] Failed to schedule daily reminder: \(error)")
        }
    }
    
    /// Cancel daily reminder
    public func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.fastingReminder]
        )
    }
    
    // MARK: - Hydration Reminders
    
    /// Schedule periodic hydration reminders during fasting
    public func scheduleHydrationReminders(interval: TimeInterval = 2 * 3600) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Stay Hydrated"
        content.body = "Remember to drink water during your fast. Staying hydrated helps maintain energy and focus."
        content.sound = .default
        content.categoryIdentifier = "HYDRATION_REMINDER"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: true
        )
        
        let request = UNNotificationRequest(
            identifier: NotificationID.hydrationReminder,
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[Notifications] Failed to schedule hydration reminder: \(error)")
        }
    }
    
    /// Cancel hydration reminders
    public func cancelHydrationReminders() {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [NotificationID.hydrationReminder]
        )
    }
    
    // MARK: - Immediate Notifications
    
    /// Send an immediate notification (for zone transitions while app is in background)
    public func sendZoneTransitionNotification(
        from oldZone: FastingZone,
        to newZone: FastingZone
    ) async {
        guard authorizationStatus == .authorized else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "\(newZone.emoji) Entered \(newZone.name)"
        content.body = "You've progressed from \(oldZone.name) to \(newZone.name). \(newZone.metabolicDescription)"
        content.sound = .default
        content.categoryIdentifier = "ZONE_TRANSITION"
        content.interruptionLevel = .timeSensitive
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "\(NotificationID.zoneTransitionPrefix)immediate_\(newZone.rawValue)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("[Notifications] Failed to send zone transition: \(error)")
        }
    }
    
    // MARK: - Cleanup
    
    /// Cancel all pending notifications
    public func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    /// Cancel all fasting-related notifications (when fast ends)
    public func cancelFastingNotifications() async {
        await cancelZoneNotifications()
        cancelGoalNotification()
        cancelHydrationReminders()
    }
    
    // MARK: - Notification Categories
    
    /// Register notification categories and actions
    public func registerNotificationCategories() {
        // Zone transition category with "Open App" action
        let openAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "Open Glasstic",
            options: .foreground
        )
        
        let zoneCategory = UNNotificationCategory(
            identifier: "ZONE_TRANSITION",
            actions: [openAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Goal reached category
        let celebrateAction = UNNotificationAction(
            identifier: "CELEBRATE",
            title: "View Progress",
            options: .foreground
        )
        
        let goalCategory = UNNotificationCategory(
            identifier: "GOAL_REACHED",
            actions: [celebrateAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Fasting reminder category
        let startFastAction = UNNotificationAction(
            identifier: "START_FAST",
            title: "Start Fast",
            options: .foreground
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: "FASTING_REMINDER",
            actions: [startFastAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Hydration category
        let hydrationCategory = UNNotificationCategory(
            identifier: "HYDRATION_REMINDER",
            actions: [],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        notificationCenter.setNotificationCategories([
            zoneCategory,
            goalCategory,
            reminderCategory,
            hydrationCategory
        ])
    }
}
