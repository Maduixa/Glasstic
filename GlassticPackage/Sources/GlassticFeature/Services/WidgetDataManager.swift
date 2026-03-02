import Foundation

/// Shared data model for widget communication via App Groups
public struct FastingWidgetData: Codable, Sendable {
    public let isActive: Bool
    public let startDate: Date?
    public let targetDuration: TimeInterval
    public let elapsed: TimeInterval
    public let currentZoneName: String
    public let currentZoneEmoji: String
    public let currentZoneColorHex: UInt32
    public let progress: Double
    public let estimatedCalories: Double
    public let nextZoneName: String?
    public let timeToNextZone: TimeInterval?
    public let protocolName: String
    public let lastUpdated: Date
    
    public init(
        isActive: Bool,
        startDate: Date?,
        targetDuration: TimeInterval,
        elapsed: TimeInterval,
        currentZoneName: String,
        currentZoneEmoji: String,
        currentZoneColorHex: UInt32,
        progress: Double,
        estimatedCalories: Double,
        nextZoneName: String?,
        timeToNextZone: TimeInterval?,
        protocolName: String
    ) {
        self.isActive = isActive
        self.startDate = startDate
        self.targetDuration = targetDuration
        self.elapsed = elapsed
        self.currentZoneName = currentZoneName
        self.currentZoneEmoji = currentZoneEmoji
        self.currentZoneColorHex = currentZoneColorHex
        self.progress = progress
        self.estimatedCalories = estimatedCalories
        self.nextZoneName = nextZoneName
        self.timeToNextZone = timeToNextZone
        self.protocolName = protocolName
        self.lastUpdated = Date()
    }
    
    /// Computed elapsed time based on start date (for real-time updates)
    public var computedElapsed: TimeInterval {
        guard isActive, let startDate else { return elapsed }
        return Date().timeIntervalSince(startDate)
    }
    
    /// Computed progress based on current elapsed
    public var computedProgress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(computedElapsed / targetDuration, 1.0)
    }
    
    /// Remaining time to goal
    public var remainingTime: TimeInterval {
        max(targetDuration - computedElapsed, 0)
    }
    
    /// Default idle state
    public static var idle: FastingWidgetData {
        FastingWidgetData(
            isActive: false,
            startDate: nil,
            targetDuration: 16 * 3600,
            elapsed: 0,
            currentZoneName: "Ready",
            currentZoneEmoji: "🍽️",
            currentZoneColorHex: 0x00D9FF,
            progress: 0,
            estimatedCalories: 0,
            nextZoneName: nil,
            timeToNextZone: nil,
            protocolName: "16:8"
        )
    }
}

/// Manager for reading/writing widget data via App Groups
public final class WidgetDataManager: Sendable {
    public static let shared = WidgetDataManager()
    
    private static let appGroupIdentifier = "group.com.glasstic.fasting"
    private static let dataKey = "fastingWidgetData"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }
    
    private init() {}
    
    /// Save widget data to App Group container
    public func save(_ data: FastingWidgetData) {
        guard let defaults = sharedDefaults else {
            print("[WidgetDataManager] Failed to access App Group container")
            return
        }
        
        do {
            let encoded = try JSONEncoder().encode(data)
            defaults.set(encoded, forKey: Self.dataKey)
            defaults.synchronize()
        } catch {
            print("[WidgetDataManager] Failed to encode widget data: \(error)")
        }
    }
    
    /// Load widget data from App Group container
    public func load() -> FastingWidgetData {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Self.dataKey) else {
            return .idle
        }
        
        do {
            return try JSONDecoder().decode(FastingWidgetData.self, from: data)
        } catch {
            print("[WidgetDataManager] Failed to decode widget data: \(error)")
            return .idle
        }
    }
}
