// filepath: /Users/hyper/src/Glasstic/Models/ColorSchemeCodable.swift
import SwiftUI

// Make SwiftUI.ColorScheme Codable so types that contain it can be encoded/decoded.
extension ColorScheme: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self))?.lowercased()
        switch value {
        case "light": self = .light
        case "dark": self = .dark
        case nil:
            // If the value is missing/null and decoding into a non-optional, pick a sensible default
            self = .light
        default:
            // Fallback to a safe default instead of failing hard
            self = .light
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = try encoder.singleValueContainer()
        switch self {
        case .light:
            try container.encode("light")
        case .dark:
            try container.encode("dark")
        @unknown default:
            try container.encode("light")
        }
    }
}
