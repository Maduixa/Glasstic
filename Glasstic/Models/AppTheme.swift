import SwiftUI

struct AppTheme: Identifiable, Codable, Hashable {
    enum MaterialBias: String, Codable {
        case ultraThin
        case thin
        case regular

        var material: Material {
            switch self {
            case .ultraThin:
                return .ultraThinMaterial
            case .thin:
                return .thinMaterial
            case .regular:
                return .regularMaterial
            }
        }
    }

    let id: UUID
    var name: String
    private var gradientHex: [String]
    private var accentHex: String
    var materialBias: MaterialBias

    init(
        id: UUID = UUID(),
        name: String,
        gradientColors: [Color],
        accent: Color,
        materialBias: MaterialBias
    ) {
        self.id = id
        self.name = name
        self.gradientHex = gradientColors.map { $0.hexString }
        self.accentHex = accent.hexString
        self.materialBias = materialBias
    }

    var gradientColors: [Color] {
        gradientHex.compactMap(Color.init(hexString:))
    }

    var accent: Color {
        Color(hexString: accentHex) ?? .white
    }

    static var allThemes: [AppTheme] {
        [
            AppTheme(
                name: "Cool Blue",
                gradientColors: [
                    Color(hex: 0x060B26),
                    Color(hex: 0x1B2C68),
                    Color(hex: 0x4F7BFB)
                ],
                accent: Color(hex: 0x8BD3FF),
                materialBias: .ultraThin
            ),
            AppTheme(
                name: "Warm Sunset",
                gradientColors: [
                    Color(hex: 0x411530),
                    Color(hex: 0xD1512D),
                    Color(hex: 0xF5C16C)
                ],
                accent: Color(hex: 0xFCECDD),
                materialBias: .thin
            ),
            AppTheme(
                name: "Monochrome",
                gradientColors: [
                    Color(hex: 0x0B0B0D),
                    Color(hex: 0x26272B),
                    Color(hex: 0x3F4152)
                ],
                accent: Color(hex: 0xE0E0E0),
                materialBias: .regular
            ),
            AppTheme(
                name: "Emerald Dawn",
                gradientColors: [
                    Color(hex: 0x062925),
                    Color(hex: 0x0B6E4F),
                    Color(hex: 0x56E39F)
                ],
                accent: Color(hex: 0xADFFDB),
                materialBias: .thin
            )
        ]
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    init?(hexString: String) {
        guard let value = UInt32(hexString, radix: 16) else { return nil }
        self.init(hex: value)
    }

    var hexString: String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return "FFFFFF"
        }

        let r = Int(red * 255.0)
        let g = Int(green * 255.0)
        let b = Int(blue * 255.0)

        return String(format: "%02X%02X%02X", r, g, b)
    }
}
