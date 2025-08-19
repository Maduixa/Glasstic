
import Foundation
import ActivityKit

struct FastingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic data for the Live Activity
        var elapsedTime: TimeInterval
        var currentZoneName: String
        var progress: Double
    }

    // Static data for the Live Activity
    var fastingGoal: TimeInterval
}
