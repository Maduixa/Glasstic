import SwiftUI
import Combine

// MARK: - Theme Definition
struct AppTheme: Identifiable, Codable {
    let id: String
    let name: String
    let primaryGradient: [CodableColor]
    let secondaryGradient: [CodableColor]
    let accentColor: CodableColor
    let progressColors: [CodableColor]
    let mode: ColorScheme?
    
    var primaryGradientColors: [Color] {
        return primaryGradient.map { $0.color }
    }
    
    var secondaryGradientColors: [Color] {
        return secondaryGradient.map { $0.color }
    }
    
    var progressGradientColors: [Color] {
        return progressColors.map { $0.color }
    }
}

// Custom Codable to support ColorScheme (not Codable by default)
extension AppTheme {
    private enum CodingKeys: String, CodingKey {
        case id, name, primaryGradient, secondaryGradient, accentColor, progressColors, mode
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        primaryGradient = try container.decode([CodableColor].self, forKey: .primaryGradient)
        secondaryGradient = try container.decode([CodableColor].self, forKey: .secondaryGradient)
        accentColor = try container.decode(CodableColor.self, forKey: .accentColor)
        progressColors = try container.decode([CodableColor].self, forKey: .progressColors)
        if let modeString = try container.decodeIfPresent(String.self, forKey: .mode) {
            switch modeString.lowercased() {
            case "light": mode = .light
            case "dark": mode = .dark
            default: mode = nil
            }
        } else {
            mode = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(primaryGradient, forKey: .primaryGradient)
        try container.encode(secondaryGradient, forKey: .secondaryGradient)
        try container.encode(accentColor, forKey: .accentColor)
        try container.encode(progressColors, forKey: .progressColors)
        let modeString: String? = {
            guard let mode = self.mode else { return nil }
            switch mode {
            case .light: return "light"
            case .dark: return "dark"
            @unknown default: return nil
            }
        }()
        try container.encodeIfPresent(modeString, forKey: .mode)
    }
}

// MARK: - Predefined Themes
extension AppTheme {
    static let defaultBlue = AppTheme(
        id: "default_blue",
        name: "Ocean Blue",
        primaryGradient: [
            CodableColor(color: .blue.opacity(0.3)),
            CodableColor(color: .gray.opacity(0.2))
        ],
        secondaryGradient: [
            CodableColor(color: .blue.opacity(0.2)),
            CodableColor(color: .cyan.opacity(0.1))
        ],
        accentColor: CodableColor(color: .blue),
        progressColors: [
            CodableColor(color: .blue.opacity(0.8)),
            CodableColor(color: .cyan.opacity(0.6))
        ],
        mode: .dark
    )
    
    static let sunsetOrange = AppTheme(
        id: "sunset_orange",
        name: "Sunset Orange",
        primaryGradient: [
            CodableColor(color: .orange.opacity(0.3)),
            CodableColor(color: .red.opacity(0.2))
        ],
        secondaryGradient: [
            CodableColor(color: .orange.opacity(0.2)),
            CodableColor(color: .yellow.opacity(0.1))
        ],
        accentColor: CodableColor(color: .orange),
        progressColors: [
            CodableColor(color: .orange.opacity(0.8)),
            CodableColor(color: .red.opacity(0.6))
        ],
        mode: .dark
    )
    
    static let forestGreen = AppTheme(
        id: "forest_green",
        name: "Forest Green",
        primaryGradient: [
            CodableColor(color: .green.opacity(0.3)),
            CodableColor(color: .mint.opacity(0.2))
        ],
        secondaryGradient: [
            CodableColor(color: .green.opacity(0.2)),
            CodableColor(color: .teal.opacity(0.1))
        ],
        accentColor: CodableColor(color: .green),
        progressColors: [
            CodableColor(color: .green.opacity(0.8)),
            CodableColor(color: .mint.opacity(0.6))
        ],
        mode: .dark
    )
    
    static let purpleNight = AppTheme(
        id: "purple_night",
        name: "Purple Night",
        primaryGradient: [
            CodableColor(color: .purple.opacity(0.3)),
            CodableColor(color: .indigo.opacity(0.2))
        ],
        secondaryGradient: [
            CodableColor(color: .purple.opacity(0.2)),
            CodableColor(color: .blue.opacity(0.1))
        ],
        accentColor: CodableColor(color: .purple),
        progressColors: [
            CodableColor(color: .purple.opacity(0.8)),
            CodableColor(color: .indigo.opacity(0.6))
        ],
        mode: .dark
    )
    
    static let lightMode = AppTheme(
        id: "light_mode",
        name: "Light Mode",
        primaryGradient: [
            CodableColor(color: .white.opacity(0.8)),
            CodableColor(color: .gray.opacity(0.3))
        ],
        secondaryGradient: [
            CodableColor(color: .white.opacity(0.6)),
            CodableColor(color: .blue.opacity(0.1))
        ],
        accentColor: CodableColor(color: .blue),
        progressColors: [
            CodableColor(color: .blue.opacity(0.7)),
            CodableColor(color: .cyan.opacity(0.5))
        ],
        mode: .light
    )
    
    static let rosePink = AppTheme(
        id: "rose_pink",
        name: "Rose Pink",
        primaryGradient: [
            CodableColor(color: .pink.opacity(0.3)),
            CodableColor(color: .red.opacity(0.2))
        ],
        secondaryGradient: [
            CodableColor(color: .pink.opacity(0.2)),
            CodableColor(color: .purple.opacity(0.1))
        ],
        accentColor: CodableColor(color: .pink),
        progressColors: [
            CodableColor(color: .pink.opacity(0.8)),
            CodableColor(color: .red.opacity(0.6))
        ],
        mode: .dark
    )
    
    static let allThemes: [AppTheme] = [
        .defaultBlue, .sunsetOrange, .forestGreen, .purpleNight, .lightMode, .rosePink
    ]
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .defaultBlue
    
    private let userDefaults = UserDefaults.standard
    private let themeKey = "selectedTheme"
    
    private init() {
        loadSavedTheme()
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveTheme()
    }
    
    private func saveTheme() {
        if let encoded = try? JSONEncoder().encode(currentTheme) {
            userDefaults.set(encoded, forKey: themeKey)
        }
    }
    
    private func loadSavedTheme() {
        guard let data = userDefaults.data(forKey: themeKey),
              let theme = try? JSONDecoder().decode(AppTheme.self, from: data) else {
            return
        }
        currentTheme = theme
    }
}
