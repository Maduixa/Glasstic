import Foundation
import SwiftUI

// This file provides watchOS-specific extensions for FastingZone
// The main FastingZone enum should be shared between iOS and watchOS

#if os(watchOS)
extension FastingZone {
    var watchColor: Color {
        switch self {
        case .postMeal:
            return Color(red: 0.8, green: 0.9, blue: 1.0)
        case .earlyFasting:
            return Color(red: 0.6, green: 0.8, blue: 1.0)
        case .fatBurning:
            return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .deepKetosis:
            return Color(red: 0.3, green: 0.5, blue: 0.9)
        }
    }

    var watchIcon: String {
        switch self {
        case .postMeal:
            return "fork.knife"
        case .earlyFasting:
            return "flame"
        case .fatBurning:
            return "bolt.fill"
        case .deepKetosis:
            return "sparkles"
        }
    }

    var shortName: String {
        switch self {
        case .postMeal:
            return "Post-Meal"
        case .earlyFasting:
            return "Early"
        case .fatBurning:
            return "Fat Burn"
        case .deepKetosis:
            return "Deep Fast"
        }
    }
}
#endif
