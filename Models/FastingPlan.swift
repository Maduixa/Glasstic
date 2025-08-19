
import Foundation

struct FastingPlan: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let duration: TimeInterval // Duration in hours

    var durationInHours: Int {
        return Int(duration / 3600)
    }

    static let defaultPlans: [FastingPlan] = [
        FastingPlan(name: "16:8", duration: 16 * 3600),
        FastingPlan(name: "18:6", duration: 18 * 3600),
        FastingPlan(name: "20:4", duration: 20 * 3600),
        FastingPlan(name: "OMAD", duration: 23 * 3600), // One Meal a Day
    ]
}
