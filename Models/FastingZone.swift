
import SwiftUI

struct FastingZone: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let duration: TimeInterval
    let color: Color
    let trivia: [String]
    let benefits: [String]
    let emoji: String

    static let allZones: [FastingZone] = [
        .anabolic, .catabolic, .fatBurning, .ketosis, .autophagy, .deepAutophagy
    ]

    static let anabolic = FastingZone(
        name: "Anabolic",
        duration: 4 * 3600, // 0-4 hours
        color: .blue,
        trivia: ["Your body is digesting and absorbing nutrients.", "Insulin levels are high."],
        benefits: ["Muscle growth and repair.", "Energy replenishment."],
        emoji: "🍽️"
    )

    static let catabolic = FastingZone(
        name: "Catabolic",
        duration: 12 * 3600, // 4-12 hours
        color: .cyan,
        trivia: ["Your body starts breaking down stored glycogen.", "Glucagon levels begin to rise."],
        benefits: ["Glycogen depletion, preparing the body for fat burning."],
        emoji: "⚡"
    )

    static let fatBurning = FastingZone(
        name: "Fat Burning",
        duration: 16 * 3600, // 12-16 hours
        color: .teal,
        trivia: ["Your body is running out of glycogen and starts burning fat for fuel.", "This is the primary goal of many intermittent fasters."],
        benefits: ["Increased fat oxidation.", "Weight loss."],
        emoji: "🔥"
    )

    static let ketosis = FastingZone(
        name: "Ketosis",
        duration: 24 * 3600, // 16-24 hours
        color: .green,
        trivia: ["Your body is now primarily using ketones for energy.", "Ketones are produced from the breakdown of fats in the liver."],
        benefits: ["Improved insulin sensitivity.", "Enhanced cognitive function."],
        emoji: "🧠"
    )

    static let autophagy = FastingZone(
        name: "Autophagy",
        duration: 48 * 3600, // 24-48 hours
        color: .yellow,
        trivia: ["Autophagy is the body's way of cleaning out damaged cells.", "This process is crucial for cellular repair and regeneration."],
        benefits: ["Cellular cleansing and recycling.", "Reduced inflammation."],
        emoji: "♻️"
    )
    
    static let deepAutophagy = FastingZone(
        name: "Deep Autophagy",
        duration: 72 * 3600, // 48-72 hours
        color: .orange,
        trivia: ["Your body is in a deep state of cellular cleaning.", "Growth hormone levels are significantly elevated."],
        benefits: ["Maximum cellular renewal.", "Potential for increased longevity."],
        emoji: "✨"
    )
}
