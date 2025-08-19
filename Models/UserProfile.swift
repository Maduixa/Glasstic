
import Foundation

struct UserProfile: Codable {
    var unlockedBadgeIDs: Set<String> = []
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalFastsCompleted: Int = 0
    var lastFastDate: Date? = nil

    mutating func unlockBadge(id: String) {
        unlockedBadgeIDs.insert(id)
    }
}
