import Foundation

/// Predefined fasting protocols with standard durations
public enum FastingProtocol: String, CaseIterable, Codable, Sendable, Identifiable {
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "20:4"
    case omad = "OMAD"
    case extended = "Extended"
    case custom = "Custom"

    public var id: String { rawValue }

    /// Display name for the protocol
    public var name: String {
        switch self {
        case .sixteenEight: return "16:8"
        case .eighteenSix: return "18:6"
        case .twentyFour: return "20:4 Warrior"
        case .omad: return "OMAD (23:1)"
        case .extended: return "Extended Fast"
        case .custom: return "Custom"
        }
    }

    /// Description of the protocol
    public var description: String {
        switch self {
        case .sixteenEight:
            return "16 hours fasting, 8 hours eating window"
        case .eighteenSix:
            return "18 hours fasting, 6 hours eating window"
        case .twentyFour:
            return "20 hours fasting, 4 hours eating window"
        case .omad:
            return "One Meal A Day - 23 hours fasting"
        case .extended:
            return "Extended fast of 24-72+ hours"
        case .custom:
            return "Set your own fasting duration"
        }
    }

    /// Default fasting duration for this protocol in seconds
    public var defaultFastingDuration: TimeInterval {
        switch self {
        case .sixteenEight: return 16 * 3600
        case .eighteenSix: return 18 * 3600
        case .twentyFour: return 20 * 3600
        case .omad: return 23 * 3600
        case .extended: return 36 * 3600
        case .custom: return 16 * 3600
        }
    }

    /// Eating window duration in seconds (for display purposes)
    public var eatingWindowDuration: TimeInterval {
        switch self {
        case .sixteenEight: return 8 * 3600
        case .eighteenSix: return 6 * 3600
        case .twentyFour: return 4 * 3600
        case .omad: return 1 * 3600
        case .extended: return 0 // No fixed eating window
        case .custom: return 0
        }
    }

    /// Whether the protocol allows custom duration adjustment
    public var allowsCustomDuration: Bool {
        switch self {
        case .extended, .custom: return true
        default: return false
        }
    }

    /// Suggested minimum hours for this protocol
    public var minimumHours: Double {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .omad: return 23
        case .extended: return 24
        case .custom: return 1
        }
    }

    /// Suggested maximum hours for this protocol
    public var maximumHours: Double {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .omad: return 23
        case .extended: return 168 // 7 days
        case .custom: return 168
        }
    }

    /// Icon name for the protocol
    public var iconName: String {
        switch self {
        case .sixteenEight: return "clock"
        case .eighteenSix: return "clock.badge.checkmark"
        case .twentyFour: return "figure.strengthtraining.traditional"
        case .omad: return "fork.knife"
        case .extended: return "infinity"
        case .custom: return "slider.horizontal.3"
        }
    }
}
