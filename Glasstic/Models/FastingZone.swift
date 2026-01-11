import Foundation

enum FastingZone: String, Codable, CaseIterable, Identifiable {
    case postMeal
    case earlyFasting
    case fatBurning
    case deepKetosis

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .postMeal:
            return "Post-Meal"
        case .earlyFasting:
            return "Early Fasting"
        case .fatBurning:
            return "Fat-Burning"
        case .deepKetosis:
            return "Deep Fast"
        }
    }

    var defaultNudges: [String] {
        switch self {
        case .postMeal:
            return [
                "Let digestion settle; hydrate lightly.",
                "Gentle start—keep water within reach."
            ]
        case .earlyFasting:
            return [
                "Glycogen stores taper—stay steady.",
                "Breathing deep keeps energy even."
            ]
        case .fatBurning:
            return [
                "Energy is shifting to fat fuel—steady pace.",
                "Fat metabolism is kicking in—keep moving mindfully."
            ]
        case .deepKetosis:
            return [
                "Cells lean on ketones—pause and reflect.",
                "Deep repair window—rest is productive."
            ]
        }
    }
}

struct FastingThresholds: Codable, Equatable {
    var postMealEndHours: Double
    var earlyFastingEndHours: Double
    var fatBurningEndHours: Double

    static let `default` = FastingThresholds(
        postMealEndHours: 4,
        earlyFastingEndHours: 12,
        fatBurningEndHours: 18
    )

    func zone(for elapsed: TimeInterval) -> FastingZone {
        let hours = elapsed / 3600
        if hours < postMealEndHours {
            return .postMeal
        } else if hours < earlyFastingEndHours {
            return .earlyFasting
        } else if hours < fatBurningEndHours {
            return .fatBurning
        } else {
            return .deepKetosis
        }
    }

    func progress(in zone: FastingZone, elapsed: TimeInterval) -> Double {
        let hours = elapsed / 3600
        switch zone {
        case .postMeal:
            return min(hours / max(postMealEndHours, 0.1), 1)
        case .earlyFasting:
            return normalizedProgress(
                hours: hours,
                lower: postMealEndHours,
                upper: earlyFastingEndHours
            )
        case .fatBurning:
            return normalizedProgress(
                hours: hours,
                lower: earlyFastingEndHours,
                upper: fatBurningEndHours
            )
        case .deepKetosis:
            return min((hours - fatBurningEndHours) / 6.0, 1) // 6h window visualisation
        }
    }

    func normalizedProgress(hours: Double, lower: Double, upper: Double) -> Double {
        guard upper > lower else { return 1 }
        return min(max((hours - lower) / (upper - lower), 0), 1)
    }

    func clamped() -> FastingThresholds {
        let postMeal = max(1, postMealEndHours)
        let early = max(postMeal + 2, earlyFastingEndHours)
        let fatBurning = max(early + 2, fatBurningEndHours)
        return FastingThresholds(
            postMealEndHours: postMeal,
            earlyFastingEndHours: early,
            fatBurningEndHours: fatBurning
        )
    }
}
