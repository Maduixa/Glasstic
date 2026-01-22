import SwiftData
import Foundation

@Model
public final class FastingSession {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date?
    public var targetDuration: TimeInterval
    public var fastingProtocol: String  // Stored as string for SwiftData compatibility
    public var note: String?
    public var caloriesBurned: Double?
    public var zoneTransitionsData: Data?  // Encoded ZoneTransition array

    public init(
        startDate: Date = Date(),
        endDate: Date? = nil,
        targetDuration: TimeInterval = 16 * 3600,
        fastingProtocol: FastingProtocol = .sixteenEight,
        note: String? = nil
    ) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
        self.targetDuration = targetDuration
        self.fastingProtocol = fastingProtocol.rawValue
        self.note = note
        self.caloriesBurned = nil
        self.zoneTransitionsData = nil
    }

    // MARK: - Computed Properties

    public var isActive: Bool {
        endDate == nil
    }

    public var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }

    /// The current fasting zone based on elapsed duration
    public var currentZone: FastingZone {
        FastingZone.zone(for: duration)
    }

    /// Progress toward the target duration (0.0 to 1.0+)
    public var progress: Double {
        guard targetDuration > 0 else { return 0 }
        return duration / targetDuration
    }

    /// Clamped progress (0.0 to 1.0)
    public var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    /// The protocol enum value
    public var protocolType: FastingProtocol {
        get { FastingProtocol(rawValue: fastingProtocol) ?? .custom }
        set { fastingProtocol = newValue.rawValue }
    }

    /// Zone transitions during this fast
    public var zoneTransitions: [ZoneTransition] {
        get {
            guard let data = zoneTransitionsData else { return [] }
            return (try? JSONDecoder().decode([ZoneTransition].self, from: data)) ?? []
        }
        set {
            zoneTransitionsData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Time remaining until target is reached
    public var remainingTime: TimeInterval {
        max(targetDuration - duration, 0)
    }

    /// Whether the target has been achieved
    public var targetReached: Bool {
        duration >= targetDuration
    }

    // MARK: - Zone Management

    /// Records a zone transition
    public func recordZoneTransition(_ zone: FastingZone) {
        var transitions = zoneTransitions
        // Only add if this zone hasn't been recorded yet
        guard !transitions.contains(where: { $0.zone == zone }) else { return }
        transitions.append(ZoneTransition(zone: zone, enteredAt: Date()))
        zoneTransitions = transitions
    }

    /// Get the time spent in a specific zone
    public func timeInZone(_ zone: FastingZone) -> TimeInterval? {
        let transitions = zoneTransitions
        guard let entry = transitions.first(where: { $0.zone == zone }) else {
            return nil
        }

        // Find when they left this zone (entered next zone)
        if let nextZone = zone.nextZone,
           let nextEntry = transitions.first(where: { $0.zone == nextZone }) {
            return nextEntry.enteredAt.timeIntervalSince(entry.enteredAt)
        }

        // Still in this zone
        if currentZone == zone {
            return Date().timeIntervalSince(entry.enteredAt)
        }

        return nil
    }
}

// MARK: - FastingSession Statistics Extension

extension FastingSession {
    /// Calculate estimated calories burned based on duration and zones
    public func estimateCalories(basalMetabolicRate: Double = 1800) -> Double {
        let hoursElapsed = duration / 3600
        let dailyRate = basalMetabolicRate / 24
        
        // Apply zone-specific metabolic multipliers
        var totalCalories: Double = 0
        var remainingHours = hoursElapsed
        
        for zone in FastingZone.allCases {
            let zoneStart = zone.startHour
            let zoneEnd = zone.endHour.isFinite ? zone.endHour : (zoneStart + remainingHours)
            
            guard remainingHours > 0 && hoursElapsed > zoneStart else { break }
            
            let hoursInZone = min(remainingHours, zoneEnd - max(zoneStart, hoursElapsed - remainingHours))
            if hoursInZone > 0 {
                totalCalories += hoursInZone * dailyRate * zone.metabolicMultiplier
                remainingHours -= hoursInZone
            }
        }
        
        return totalCalories
    }
}
