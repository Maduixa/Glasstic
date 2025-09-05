
import SwiftUI

struct FastingZone: Identifiable, Equatable {
    let id = UUID()
    let name: String
    // Threshold (seconds since start) at which this zone becomes active
    let threshold: TimeInterval
    let color: Color
    let trivia: [String]
    let benefits: [String]
    let emoji: String

    static let allZones: [FastingZone] = [
        .anabolic, .catabolic, .fatBurning, .ketosis, .autophagy, .deepAutophagy
    ]

    static let anabolic = FastingZone(
        name: "Anabolic",
        threshold: 4 * 3600, // becomes active at 4h mark
        color: .blue,
        trivia: ["Your body is digesting and absorbing nutrients.", "Insulin levels are high."],
        benefits: ["Muscle growth and repair.", "Energy replenishment."],
        emoji: "🍽️"
    )

    static let catabolic = FastingZone(
        name: "Catabolic",
        threshold: 12 * 3600, // becomes active at 12h mark
        color: .cyan,
        trivia: ["Your body starts breaking down stored glycogen.", "Glucagon levels begin to rise."],
        benefits: ["Glycogen depletion, preparing the body for fat burning."],
        emoji: "⚡"
    )

    static let fatBurning = FastingZone(
        name: "Fat Burning",
        threshold: 16 * 3600, // becomes active at 16h mark
        color: .teal,
        trivia: ["Your body is running out of glycogen and starts burning fat for fuel.", "This is the primary goal of many intermittent fasters."],
        benefits: ["Increased fat oxidation.", "Weight loss."],
        emoji: "🔥"
    )

    static let ketosis = FastingZone(
        name: "Ketosis",
        threshold: 24 * 3600, // becomes active at 24h mark
        color: .green,
        trivia: ["Your body is now primarily using ketones for energy.", "Ketones are produced from the breakdown of fats in the liver."],
        benefits: ["Improved insulin sensitivity.", "Enhanced cognitive function."],
        emoji: "🧠"
    )

    static let autophagy = FastingZone(
        name: "Autophagy",
        threshold: 48 * 3600, // becomes active at 48h mark
        color: .yellow,
        trivia: ["Autophagy is the body's way of cleaning out damaged cells.", "This process is crucial for cellular repair and regeneration."],
        benefits: ["Cellular cleansing and recycling.", "Reduced inflammation."],
        emoji: "♻️"
    )
    
    static let deepAutophagy = FastingZone(
        name: "Deep Autophagy",
        threshold: 72 * 3600, // becomes active at 72h mark
        color: .orange,
        trivia: ["Your body is in a deep state of cellular cleaning.", "Growth hormone levels are significantly elevated."],
        benefits: ["Maximum cellular renewal.", "Potential for increased longevity."],
        emoji: "✨"
    )
}
