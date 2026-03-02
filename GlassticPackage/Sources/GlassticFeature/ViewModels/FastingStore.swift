import SwiftUI
import WidgetKit

@MainActor
@Observable
public final class FastingStore {
    // MARK: - Storage Keys
    private static let targetDurationKey = "glasstic.targetDuration"
    private static let protocolKey = "glasstic.protocol"
    private static let notificationsEnabledKey = "glasstic.notificationsEnabled"
    private static let healthKitEnabledKey = "glasstic.healthKitEnabled"

    // MARK: - Published State
    public private(set) var activeSession: FastingSession?
    public private(set) var elapsed: TimeInterval = 0
    public private(set) var currentZone: FastingZone = .fedState
    public private(set) var previousZone: FastingZone = .fedState
    
    // MARK: - HealthKit State
    public private(set) var userProfile: HealthKitManager.UserHealthProfile?
    public private(set) var healthKitAuthorized = false
    
    // MARK: - Notification State
    public private(set) var notificationsAuthorized = false

    // MARK: - Settings
    public var targetDuration: TimeInterval {
        didSet {
            defaults.set(targetDuration, forKey: Self.targetDurationKey)
            syncWidgetData()
        }
    }
    public var selectedProtocol: FastingProtocol {
        didSet {
            defaults.set(selectedProtocol.rawValue, forKey: Self.protocolKey)
            if !selectedProtocol.allowsCustomDuration {
                targetDuration = selectedProtocol.defaultFastingDuration
            }
            syncWidgetData()
        }
    }
    public var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: Self.notificationsEnabledKey) }
    }
    public var healthKitEnabled: Bool {
        didSet { defaults.set(healthKitEnabled, forKey: Self.healthKitEnabledKey) }
    }

    // MARK: - Private
    private var timer: Timer?
    private let dataService = DataService.shared
    private let healthKit = HealthKitManager.shared
    private let notifications = NotificationManager.shared
    private let widgetData = WidgetDataManager.shared
    private let defaults = UserDefaults.standard
    private var widgetUpdateCounter = 0

    // MARK: - Initialization

    public init(targetDuration: TimeInterval = 16 * 3600) {
        // Load saved protocol
        let savedProtocol = defaults.string(forKey: Self.protocolKey)
            .flatMap { FastingProtocol(rawValue: $0) } ?? .sixteenEight
        self.selectedProtocol = savedProtocol

        // Load saved duration or use protocol default
        let storedDuration = defaults.double(forKey: Self.targetDurationKey)
        self.targetDuration = storedDuration > 0 ? storedDuration : savedProtocol.defaultFastingDuration
        
        // Load notification and HealthKit preferences
        self.notificationsEnabled = defaults.bool(forKey: Self.notificationsEnabledKey)
        self.healthKitEnabled = defaults.bool(forKey: Self.healthKitEnabledKey)

        loadActiveSession()
        if activeSession != nil {
            startTimer()
        }
        
        // Initialize services
        Task {
            await initializeServices()
        }
        
        // Initial widget sync
        syncWidgetData()
    }
    
    // MARK: - Service Initialization
    
    private func initializeServices() async {
        // Register notification categories
        notifications.registerNotificationCategories()
        
        // Check authorization status
        await notifications.checkAuthorizationStatus()
        notificationsAuthorized = notifications.authorizationStatus == .authorized
        
        healthKitAuthorized = healthKit.checkAuthorizationStatus() == .authorized
        
        // Load user profile if HealthKit is authorized
        if healthKitAuthorized {
            await refreshHealthProfile()
        }
    }

    // MARK: - Computed Properties

    public var progress: Double {
        guard elapsed > 0 else { return 0 }
        return min(elapsed / max(targetDuration, 1), 1.0)
    }

    public var isActive: Bool {
        activeSession != nil
    }

    public var remainingTime: TimeInterval {
        max(targetDuration - elapsed, 0)
    }

    public var targetReached: Bool {
        elapsed >= targetDuration
    }

    public var zoneProgress: Double {
        FastingZone.zoneProgress(for: elapsed)
    }

    public var timeToNextZone: TimeInterval? {
        FastingZone.timeToNextZone(for: elapsed)
    }

    public var nextZone: FastingZone? {
        currentZone.nextZone
    }

    public var estimatedCalories: Double {
        // Use HealthKit BMR if available, otherwise use session estimate
        if let bmr = userProfile?.calculatedBMR ?? userProfile?.estimatedBMR {
            let hours = elapsed / 3600
            let hourlyBurn = bmr / 24
            let metabolicMultiplier = currentZone.metabolicMultiplier
            return hours * hourlyBurn * metabolicMultiplier
        }
        return activeSession?.estimateCalories() ?? 0
    }

    public var accentColor: Color {
        currentZone.color
    }
    
    // MARK: - HealthKit Actions
    
    /// Request HealthKit authorization
    public func requestHealthKitAuthorization() async {
        do {
            try await healthKit.requestAuthorization()
            healthKitAuthorized = healthKit.authorizationStatus == .authorized
            healthKitEnabled = healthKitAuthorized
            
            if healthKitAuthorized {
                await refreshHealthProfile()
                await healthKit.enableBackgroundDelivery()
            }
        } catch {
            print("[FastingStore] HealthKit authorization failed: \(error)")
            healthKitAuthorized = false
        }
    }
    
    /// Refresh health profile from HealthKit
    public func refreshHealthProfile() async {
        guard healthKitAuthorized else { return }
        
        do {
            userProfile = try await healthKit.fetchUserProfile()
        } catch {
            print("[FastingStore] Failed to fetch health profile: \(error)")
        }
    }
    
    // MARK: - Notification Actions
    
    /// Request notification authorization
    public func requestNotificationAuthorization() async {
        do {
            let granted = try await notifications.requestAuthorization()
            notificationsAuthorized = granted
            notificationsEnabled = granted
        } catch {
            print("[FastingStore] Notification authorization failed: \(error)")
            notificationsAuthorized = false
        }
    }

    // MARK: - Fasting Actions

    public func startFast() {
        let session = dataService.startFast(
            targetDuration: targetDuration,
            protocol: selectedProtocol
        )
        activeSession = session
        elapsed = 0
        currentZone = FastingZone.fedState
        previousZone = FastingZone.fedState
        session.recordZoneTransition(FastingZone.fedState)
        startTimer()
        
        // Schedule notifications
        if notificationsEnabled {
            Task {
                await scheduleNotifications(for: session)
            }
        }
        
        // Sync widget data
        syncWidgetData()
    }

    public func endFast() {
        guard let session = activeSession else { return }
        
        // Update calories before ending
        session.caloriesBurned = estimatedCalories
        
        dataService.endFast(session)
        stopTimer()
        
        // Save to HealthKit if enabled
        if healthKitEnabled {
            let startDate = session.startDate
            let calories = session.caloriesBurned ?? 0
            Task {
                try? await healthKit.saveFastingSession(
                    startDate: startDate,
                    endDate: Date(),
                    caloriesBurned: calories
                )
            }
        }
        
        // Cancel pending notifications
        Task {
            await notifications.cancelFastingNotifications()
        }
        
        activeSession = nil
        elapsed = 0
        currentZone = .fedState
        previousZone = .fedState
        
        // Sync widget data
        syncWidgetData()
    }

    public func updateStartDate(_ newStart: Date) {
        guard let session = activeSession else { return }
        session.startDate = newStart
        elapsed = session.duration
        dataService.save()
    }

    public func updateTargetDuration(hours: Double) {
        let clamped = min(max(hours, 1), 168)
        targetDuration = clamped * 3600
    }

    public func selectProtocol(_ protocol: FastingProtocol) {
        selectedProtocol = `protocol`
        if !`protocol`.allowsCustomDuration {
            targetDuration = `protocol`.defaultFastingDuration
        }
    }

    // MARK: - Private Methods

    private func loadActiveSession() {
        activeSession = dataService.fetchActiveFast()
        if let session = activeSession {
            elapsed = session.duration
            currentZone = FastingZone.zone(for: elapsed)
            previousZone = currentZone
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsed()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func updateElapsed() {
        guard let session = activeSession else { return }
        elapsed = session.duration

        // Check for zone transitions
        let newZone = FastingZone.zone(for: elapsed)
        if newZone != currentZone {
            previousZone = currentZone
            currentZone = newZone
            session.recordZoneTransition(newZone)
            onZoneTransition(from: previousZone, to: newZone)
        }
        
        // Sync widget data every 60 seconds to avoid excessive writes
        widgetUpdateCounter += 1
        if widgetUpdateCounter >= 60 {
            widgetUpdateCounter = 0
            syncWidgetData()
        }
    }

    private func onZoneTransition(from oldZone: FastingZone, to newZone: FastingZone) {
        // Haptic feedback for zone transitions
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif

        // Send notification if app is in background and notifications enabled
        if notificationsEnabled {
            Task {
                await notifications.sendZoneTransitionNotification(from: oldZone, to: newZone)
            }
        }
        
        // Sync widget data on zone change
        syncWidgetData()
    }
    
    private func scheduleNotifications(for session: FastingSession) async {
        let startDate = session.startDate
        
        // Schedule zone transition notifications
        await notifications.scheduleAllZoneNotifications(
            fastStartDate: startDate,
            currentZone: currentZone
        )
        
        // Schedule goal notification
        let goalDate = startDate.addingTimeInterval(targetDuration)
        await notifications.scheduleGoalNotification(triggerDate: goalDate)
        
        // Schedule hydration reminders (every 2 hours)
        await notifications.scheduleHydrationReminders(interval: 2 * 3600)
    }
    
    // MARK: - Widget Data Sync
    
    private func syncWidgetData() {
        let data = FastingWidgetData(
            isActive: isActive,
            startDate: activeSession?.startDate,
            targetDuration: targetDuration,
            elapsed: elapsed,
            currentZoneName: currentZone.name,
            currentZoneEmoji: currentZone.emoji,
            currentZoneColorHex: currentZone.hexValue,
            progress: progress,
            estimatedCalories: estimatedCalories,
            nextZoneName: nextZone?.name,
            timeToNextZone: timeToNextZone,
            protocolName: selectedProtocol.name
        )
        
        widgetData.save(data)
        
        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
}

// MARK: - Time Formatting Helpers

extension FastingStore {
    /// Format elapsed time as HH:MM:SS
    public var elapsedFormatted: String {
        formatDuration(elapsed)
    }

    /// Format remaining time as HH:MM:SS
    public var remainingFormatted: String {
        formatDuration(remainingTime)
    }

    /// Format time to next zone
    public var timeToNextZoneFormatted: String? {
        guard let time = timeToNextZone else { return nil }
        return formatDuration(time)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration.rounded(.down)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
