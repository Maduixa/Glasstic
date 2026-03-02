import SwiftUI

/// The 8 metabolic fasting zones as defined in the Glasstic specification.
/// Each zone represents a distinct metabolic state with specific health benefits.
public enum FastingZone: Int, CaseIterable, Codable, Sendable, Identifiable {
    case fedState = 0
    case earlyFasting = 1
    case glycogenDepletion = 2
    case fatBurning = 3
    case ketosis = 4
    case autophagyActivation = 5
    case growthHormoneSurge = 6
    case deepRenewal = 7

    public var id: Int { rawValue }

    /// The display name for this zone
    public var name: String {
        switch self {
        case .fedState: return "Fed State"
        case .earlyFasting: return "Early Fasting"
        case .glycogenDepletion: return "Glycogen Depletion"
        case .fatBurning: return "Fat Burning"
        case .ketosis: return "Ketosis"
        case .autophagyActivation: return "Autophagy Activation"
        case .growthHormoneSurge: return "Growth Hormone Surge"
        case .deepRenewal: return "Deep Renewal"
        }
    }

    /// Short display name for compact UI
    public var shortName: String {
        switch self {
        case .fedState: return "FED"
        case .earlyFasting: return "EARLY"
        case .glycogenDepletion: return "GLYCOGEN"
        case .fatBurning: return "FAT BURN"
        case .ketosis: return "KETOSIS"
        case .autophagyActivation: return "AUTOPHAGY"
        case .growthHormoneSurge: return "HGH SURGE"
        case .deepRenewal: return "RENEWAL"
        }
    }

    /// Emoji representation for the zone
    public var emoji: String {
        switch self {
        case .fedState: return "\u{1F37D}\u{FE0F}" // plate with cutlery
        case .earlyFasting: return "\u{1F324}\u{FE0F}" // sun behind small cloud
        case .glycogenDepletion: return "\u{26A1}" // lightning bolt
        case .fatBurning: return "\u{1F525}" // fire
        case .ketosis: return "\u{1F9EA}" // test tube
        case .autophagyActivation: return "\u{267B}\u{FE0F}" // recycling symbol
        case .growthHormoneSurge: return "\u{1F4AA}" // flexed biceps
        case .deepRenewal: return "\u{2728}" // sparkles
        }
    }

    /// Primary color for this zone (from spec)
    public var color: Color {
        Color(hex: hexValue)
    }
    
    /// Hex color value for this zone (for sharing with widgets)
    public var hexValue: UInt32 {
        switch self {
        case .fedState: return 0x4CAF50 // Green
        case .earlyFasting: return 0x8BC34A // Light Green
        case .glycogenDepletion: return 0xCDDC39 // Lime
        case .fatBurning: return 0xFFC107 // Amber
        case .ketosis: return 0xFF9800 // Orange
        case .autophagyActivation: return 0xFF5722 // Deep Orange
        case .growthHormoneSurge: return 0xE91E63 // Pink
        case .deepRenewal: return 0x9C27B0 // Purple
        }
    }

    /// Hour threshold when this zone begins
    public var startHour: Double {
        switch self {
        case .fedState: return 0
        case .earlyFasting: return 3
        case .glycogenDepletion: return 8
        case .fatBurning: return 12
        case .ketosis: return 16
        case .autophagyActivation: return 24
        case .growthHormoneSurge: return 36
        case .deepRenewal: return 48
        }
    }

    /// Hour when this zone ends (next zone begins)
    public var endHour: Double {
        switch self {
        case .fedState: return 3
        case .earlyFasting: return 8
        case .glycogenDepletion: return 12
        case .fatBurning: return 16
        case .ketosis: return 24
        case .autophagyActivation: return 36
        case .growthHormoneSurge: return 48
        case .deepRenewal: return .infinity
        }
    }

    /// Description of what happens metabolically in this zone
    public var metabolicDescription: String {
        switch self {
        case .fedState:
            return "Digestion active, insulin elevated, nutrients being absorbed"
        case .earlyFasting:
            return "Insulin dropping, body transitioning from fed to fasted state"
        case .glycogenDepletion:
            return "Liver glycogen stores depleting, gluconeogenesis beginning"
        case .fatBurning:
            return "Lipolysis accelerates, ketone production starts"
        case .ketosis:
            return "Significant ketone elevation, enhanced fat oxidation"
        case .autophagyActivation:
            return "Cellular cleanup and recycling processes activate"
        case .growthHormoneSurge:
            return "HGH peaks (up to 5x baseline), deep cellular repair"
        case .deepRenewal:
            return "Extended benefits, stem cell activation, immune reset"
        }
    }

    /// Metabolic multiplier for calorie estimation (ketosis burns ~5% more)
    public var metabolicMultiplier: Double {
        switch self {
        case .fedState: return 1.0
        case .earlyFasting: return 1.0
        case .glycogenDepletion: return 1.02
        case .fatBurning: return 1.03
        case .ketosis: return 1.05
        case .autophagyActivation: return 1.06
        case .growthHormoneSurge: return 1.07
        case .deepRenewal: return 1.08
        }
    }

    /// Determines the zone for a given fasting duration
    /// - Parameter duration: Time interval since fast started
    /// - Returns: The current fasting zone
    public static func zone(for duration: TimeInterval) -> FastingZone {
        let hours = duration / 3600
        
        if hours >= 48 { return .deepRenewal }
        if hours >= 36 { return .growthHormoneSurge }
        if hours >= 24 { return .autophagyActivation }
        if hours >= 16 { return .ketosis }
        if hours >= 12 { return .fatBurning }
        if hours >= 8 { return .glycogenDepletion }
        if hours >= 3 { return .earlyFasting }
        return .fedState
    }

    /// Progress within the current zone (0.0 to 1.0)
    /// - Parameter duration: Time interval since fast started
    /// - Returns: Progress through the current zone
    public static func zoneProgress(for duration: TimeInterval) -> Double {
        let zone = zone(for: duration)
        let hours = duration / 3600
        
        guard zone.endHour.isFinite else {
            // Deep renewal has no end, use 72h as reference
            let progressHours = hours - zone.startHour
            return min(progressHours / 24.0, 1.0)
        }
        
        let zoneHours = zone.endHour - zone.startHour
        let progressHours = hours - zone.startHour
        return min(max(progressHours / zoneHours, 0), 1)
    }

    /// Time remaining until next zone
    /// - Parameter duration: Time interval since fast started
    /// - Returns: Time interval until next zone, or nil if in deep renewal
    public static func timeToNextZone(for duration: TimeInterval) -> TimeInterval? {
        let zone = zone(for: duration)
        guard zone.endHour.isFinite else { return nil }
        
        let hours = duration / 3600
        let hoursRemaining = zone.endHour - hours
        return max(hoursRemaining * 3600, 0)
    }

    /// The next zone after this one
    public var nextZone: FastingZone? {
        FastingZone(rawValue: rawValue + 1)
    }
}

// MARK: - ZoneTransition

/// Records when a user entered a specific fasting zone
public struct ZoneTransition: Codable, Sendable, Equatable {
    public let zone: FastingZone
    public let enteredAt: Date

    public init(zone: FastingZone, enteredAt: Date = Date()) {
        self.zone = zone
        self.enteredAt = enteredAt
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
