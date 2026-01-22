import SwiftUI
import WidgetKit

// MARK: - Shared Data Model (duplicated for widget extension)

struct FastingWidgetData: Codable {
    let isActive: Bool
    let startDate: Date?
    let targetDuration: TimeInterval
    let elapsed: TimeInterval
    let currentZoneName: String
    let currentZoneEmoji: String
    let currentZoneColorHex: UInt32
    let progress: Double
    let estimatedCalories: Double
    let nextZoneName: String?
    let timeToNextZone: TimeInterval?
    let protocolName: String
    let lastUpdated: Date
    
    var computedElapsed: TimeInterval {
        guard isActive, let startDate else { return elapsed }
        return Date().timeIntervalSince(startDate)
    }
    
    var computedProgress: Double {
        guard targetDuration > 0 else { return 0 }
        return min(computedElapsed / targetDuration, 1.0)
    }
    
    var remainingTime: TimeInterval {
        max(targetDuration - computedElapsed, 0)
    }
    
    var zoneColor: Color {
        Color(hex: currentZoneColorHex)
    }
    
    static var idle: FastingWidgetData {
        FastingWidgetData(
            isActive: false,
            startDate: nil,
            targetDuration: 16 * 3600,
            elapsed: 0,
            currentZoneName: "Ready",
            currentZoneEmoji: "🍽️",
            currentZoneColorHex: 0x00D9FF,
            progress: 0,
            estimatedCalories: 0,
            nextZoneName: nil,
            timeToNextZone: nil,
            protocolName: "16:8",
            lastUpdated: Date()
        )
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

// MARK: - Widget Data Provider

final class WidgetDataProvider {
    static let shared = WidgetDataProvider()
    
    private static let appGroupIdentifier = "group.com.glasstic.fasting"
    private static let dataKey = "fastingWidgetData"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: Self.appGroupIdentifier)
    }
    
    func load() -> FastingWidgetData {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: Self.dataKey) else {
            return .idle
        }
        
        do {
            return try JSONDecoder().decode(FastingWidgetData.self, from: data)
        } catch {
            return .idle
        }
    }
}

// MARK: - Timeline Provider

struct FastingTimelineProvider: TimelineProvider {
    typealias Entry = FastingWidgetEntry
    
    func placeholder(in context: Context) -> FastingWidgetEntry {
        FastingWidgetEntry(date: Date(), data: .idle)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FastingWidgetEntry) -> Void) {
        let data = WidgetDataProvider.shared.load()
        completion(FastingWidgetEntry(date: Date(), data: data))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FastingWidgetEntry>) -> Void) {
        let data = WidgetDataProvider.shared.load()
        let currentDate = Date()
        
        // Create entries for the next hour (update every minute when active)
        var entries: [FastingWidgetEntry] = []
        
        if data.isActive {
            // When fasting is active, update every minute
            for minuteOffset in 0..<60 {
                let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
                entries.append(FastingWidgetEntry(date: entryDate, data: data))
            }
        } else {
            // When idle, just one entry
            entries.append(FastingWidgetEntry(date: currentDate, data: data))
        }
        
        // Refresh after the last entry
        let refreshDate = entries.last?.date.addingTimeInterval(60) ?? currentDate.addingTimeInterval(3600)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}

// MARK: - Widget Entry

struct FastingWidgetEntry: TimelineEntry {
    let date: Date
    let data: FastingWidgetData
}

// MARK: - Time Formatting

extension TimeInterval {
    var formattedHHMMSS: String {
        let totalSeconds = max(Int(self.rounded(.down)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var formattedHHMM: String {
        let totalSeconds = max(Int(self.rounded(.down)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        return String(format: "%dh %02dm", hours, minutes)
    }
    
    var formattedShort: String {
        let totalSeconds = max(Int(self.rounded(.down)), 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Small Widget View

struct SmallWidgetView: View {
    let entry: FastingWidgetEntry
    
    var body: some View {
        let data = entry.data
        
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    data.zoneColor.opacity(0.8),
                    data.zoneColor.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(spacing: 8) {
                // Zone emoji
                Text(data.currentZoneEmoji)
                    .font(.system(size: 36))
                
                // Elapsed time
                if data.isActive {
                    Text(data.computedElapsed.formattedHHMMSS)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                } else {
                    Text("Start Fast")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                
                // Zone name
                Text(data.currentZoneName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding()
        }
        .containerBackground(for: .widget) {
            data.zoneColor.opacity(0.3)
        }
    }
}

// MARK: - Medium Widget View

struct MediumWidgetView: View {
    let entry: FastingWidgetEntry
    
    var body: some View {
        let data = entry.data
        
        HStack(spacing: 16) {
            // Mini circular gauge
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: data.computedProgress)
                    .stroke(
                        data.zoneColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 2) {
                    Text(data.currentZoneEmoji)
                        .font(.system(size: 24))
                    Text("\(Int(data.computedProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(width: 80, height: 80)
            
            // Info section
            VStack(alignment: .leading, spacing: 6) {
                // Zone name
                Text(data.currentZoneName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                
                // Elapsed time
                if data.isActive {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                        Text(data.computedElapsed.formattedHHMMSS)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white.opacity(0.9))
                    
                    // Next zone countdown
                    if let nextZone = data.nextZoneName, let timeToNext = data.timeToNextZone {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 12))
                            Text("\(nextZone) in \(timeToNext.formattedShort)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundStyle(.white.opacity(0.7))
                    }
                } else {
                    Text("Tap to start fasting")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    
                    Text(data.protocolName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(data.zoneColor)
                }
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.14),
                    Color(red: 0.02, green: 0.06, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: FastingWidgetEntry
    
    var body: some View {
        let data = entry.data
        
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Glasstic")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(data.protocolName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(data.zoneColor)
            }
            
            // Large circular gauge
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                
                Circle()
                    .trim(from: 0, to: data.computedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [data.zoneColor.opacity(0.6), data.zoneColor],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text(data.currentZoneEmoji)
                        .font(.system(size: 40))
                    
                    if data.isActive {
                        Text(data.computedElapsed.formattedHHMMSS)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                    } else {
                        Text("Ready")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Text(data.currentZoneName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            .frame(width: 160, height: 160)
            
            // Stats row
            HStack(spacing: 24) {
                StatColumn(
                    icon: "flame.fill",
                    value: "\(Int(data.estimatedCalories))",
                    label: "kcal",
                    color: .orange
                )
                
                StatColumn(
                    icon: "target",
                    value: "\(Int(data.targetDuration / 3600))h",
                    label: "goal",
                    color: data.zoneColor
                )
                
                StatColumn(
                    icon: "chart.bar.fill",
                    value: "\(Int(data.computedProgress * 100))%",
                    label: "progress",
                    color: .green
                )
            }
            
            Spacer()
        }
        .padding()
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.14),
                    Color(red: 0.02, green: 0.06, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

struct StatColumn: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

// MARK: - Lock Screen Widgets

struct CircularAccessoryView: View {
    let entry: FastingWidgetEntry
    
    var body: some View {
        let data = entry.data
        
        ZStack {
            AccessoryWidgetBackground()
            
            Gauge(value: data.computedProgress) {
                Text(data.currentZoneEmoji)
            }
            .gaugeStyle(.accessoryCircular)
            .tint(data.zoneColor)
        }
    }
}

struct RectangularAccessoryView: View {
    let entry: FastingWidgetEntry
    
    var body: some View {
        let data = entry.data
        
        HStack(spacing: 8) {
            Text(data.currentZoneEmoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                if data.isActive {
                    Text(data.computedElapsed.formattedHHMM)
                        .font(.headline)
                        .monospacedDigit()
                } else {
                    Text("Not Fasting")
                        .font(.headline)
                }
                
                Text(data.currentZoneName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct InlineAccessoryView: View {
    let entry: FastingWidgetEntry
    
    var body: some View {
        let data = entry.data
        
        if data.isActive {
            Text("\(data.currentZoneEmoji) \(data.computedElapsed.formattedHHMM) - \(data.currentZoneName)")
        } else {
            Text("\(data.currentZoneEmoji) Ready to fast")
        }
    }
}

// MARK: - Main Widget

@main
struct GlassticWidgets: WidgetBundle {
    var body: some Widget {
        FastingWidget()
        FastingLockScreenWidget()
    }
}

struct FastingWidget: Widget {
    let kind: String = "FastingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingTimelineProvider()) { entry in
            FastingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fasting Timer")
        .description("Track your intermittent fasting progress")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct FastingWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FastingWidgetEntry
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct FastingLockScreenWidget: Widget {
    let kind: String = "FastingLockScreenWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastingTimelineProvider()) { entry in
            LockScreenWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Fasting Status")
        .description("Quick glance at your fasting status")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: FastingWidgetEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularAccessoryView(entry: entry)
        case .accessoryRectangular:
            RectangularAccessoryView(entry: entry)
        case .accessoryInline:
            InlineAccessoryView(entry: entry)
        default:
            CircularAccessoryView(entry: entry)
        }
    }
}

// MARK: - Previews

#Preview("Small", as: .systemSmall) {
    FastingWidget()
} timeline: {
    FastingWidgetEntry(date: .now, data: .idle)
    FastingWidgetEntry(date: .now, data: FastingWidgetData(
        isActive: true,
        startDate: Date().addingTimeInterval(-4 * 3600),
        targetDuration: 16 * 3600,
        elapsed: 4 * 3600,
        currentZoneName: "Early Fasting",
        currentZoneEmoji: "🌤️",
        currentZoneColorHex: 0x8BC34A,
        progress: 0.25,
        estimatedCalories: 180,
        nextZoneName: "Glycogen Depletion",
        timeToNextZone: 4 * 3600,
        protocolName: "16:8",
        lastUpdated: Date()
    ))
}

#Preview("Medium", as: .systemMedium) {
    FastingWidget()
} timeline: {
    FastingWidgetEntry(date: .now, data: FastingWidgetData(
        isActive: true,
        startDate: Date().addingTimeInterval(-12 * 3600),
        targetDuration: 16 * 3600,
        elapsed: 12 * 3600,
        currentZoneName: "Fat Burning",
        currentZoneEmoji: "🔥",
        currentZoneColorHex: 0xFFC107,
        progress: 0.75,
        estimatedCalories: 540,
        nextZoneName: "Ketosis",
        timeToNextZone: 4 * 3600,
        protocolName: "16:8",
        lastUpdated: Date()
    ))
}
