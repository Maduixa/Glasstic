
import Foundation

class GamificationManager {
    static let shared = GamificationManager()
    private var userProfile: UserProfile

    private let profileURL: URL

    private init() {
        do {
            let documentsDirectory = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            self.profileURL = documentsDirectory.appendingPathComponent("user_profile.json")
        } catch {
            fatalError("Could not find documents directory")
        }
        self.userProfile = Self.loadProfile(from: profileURL)
    }

    private static func loadProfile(from url: URL) -> UserProfile {
        if let data = try? Data(contentsOf: url) {
            if let profile = try? JSONDecoder().decode(UserProfile.self, from: data) {
                return profile
            }
        }
        return UserProfile()
    }

    private func saveProfile() {
        do {
            let data = try JSONEncoder().encode(userProfile)
            try data.write(to: profileURL, options: .atomic)
        } catch {
            print("Error saving user profile: \(error.localizedDescription)")
        }
    }

    func processCompletedFast(startDate: Date, endDate: Date) {
        let duration = endDate.timeIntervalSince(startDate)
        
        // Update Stats
        userProfile.totalFastsCompleted += 1
        
        // Update Streaks
        updateStreak(for: endDate)
        
        // Check for Badges
        checkAndAwardBadges(duration: duration)
        
        saveProfile()
    }

    private func updateStreak(for completionDate: Date) {
        if let lastFast = userProfile.lastFastDate {
            if Calendar.current.isDate(completionDate, inSameDayAs: lastFast.addingTimeInterval(24*3600)) {
                // Consecutive days
                userProfile.currentStreak += 1
            } else if !Calendar.current.isDate(completionDate, inSameDayAs: lastFast) {
                // Not a consecutive day, reset streak
                userProfile.currentStreak = 1
            }
        } else {
            // First fast
            userProfile.currentStreak = 1
        }

        if userProfile.currentStreak > userProfile.longestStreak {
            userProfile.longestStreak = userProfile.currentStreak
        }
        userProfile.lastFastDate = completionDate
    }

    private func checkAndAwardBadges(duration: TimeInterval) {
        // First Fast
        if userProfile.totalFastsCompleted == 1 {
            userProfile.unlockBadge(id: "first_fast")
        }
        // Total Fasts
        if userProfile.totalFastsCompleted >= 10 {
            userProfile.unlockBadge(id: "10_fasts")
        }
        if userProfile.totalFastsCompleted >= 50 {
            userProfile.unlockBadge(id: "50_fasts")
        }
        // Streaks
        if userProfile.currentStreak >= 7 {
            userProfile.unlockBadge(id: "7_day_streak")
        }
        if userProfile.currentStreak >= 30 {
            userProfile.unlockBadge(id: "30_day_streak")
        }
        // Duration
        if duration >= 24 * 3600 {
            userProfile.unlockBadge(id: "24_hour_fast")
        }
        // Zones
        if duration >= FastingZone.autophagy.duration {
            userProfile.unlockBadge(id: "autophagy_unlocked")
        }
    }
    
    func getProfile() -> UserProfile {
        return userProfile
    }
}
