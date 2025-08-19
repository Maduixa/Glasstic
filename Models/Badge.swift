
import SwiftUI

struct Badge: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let description: String
    let icon: String // SF Symbol name
    let color: CodableColor

    static let allBadges: [Badge] = [
        Badge(id: "first_fast", name: "First Fast", description: "Completed your first fast.", icon: "play.circle", color: .init(color: .blue)),
        Badge(id: "7_day_streak", name: "7-Day Warrior", description: "Completed a 7-day fasting streak.", icon: "flame.fill", color: .init(color: .orange)),
        Badge(id: "30_day_streak", name: "Month of Consistency", description: "Completed a 30-day fasting streak.", icon: "crown.fill", color: .init(color: .yellow)),
        Badge(id: "10_fasts", name: "Fast Follower", description: "Completed 10 fasts.", icon: "10.circle", color: .init(color: .green)),
        Badge(id: "50_fasts", name: "Fasting Fanatic", description: "Completed 50 fasts.", icon: "50.circle", color: .init(color: .teal)),
        Badge(id: "24_hour_fast", name: "24-Hour Club", description: "Completed a 24-hour fast.", icon: "clock.arrow.2.circlepath", color: .init(color: .purple)),
        Badge(id: "autophagy_unlocked", name: "Cellular Cleaner", description: "Reached the Autophagy zone.", icon: "atom", color: .init(color: .indigo))
    ]
    
    static func badge(for id: String) -> Badge? {
        return allBadges.first { $0.id == id }
    }
}

// Helper to make Color Codable
struct CodableColor: Codable, Hashable {
    let red: Double
    let green: Double
    let blue: Double
    let opacity: Double

    init(color: Color) {
        #if canImport(UIKit)
        let uiColor = UIColor(color)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        self.red = Double(r)
        self.green = Double(g)
        self.blue = Double(b)
        self.opacity = Double(a)
        #elseif canImport(AppKit)
        let nsColor = NSColor(color)
        self.red = Double(nsColor.redComponent)
        self.green = Double(nsColor.greenComponent)
        self.blue = Double(nsColor.blueComponent)
        self.opacity = Double(nsColor.alphaComponent)
        #else
        // Default for other platforms, like watchOS
        self.red = 0
        self.green = 0
        self.blue = 0
        self.opacity = 1
        #endif
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
