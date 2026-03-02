import ClockKit
import SwiftUI
import WidgetKit

// MARK: - Complication Timeline Provider

struct GlassticComplicationProvider: TimelineProvider {
    typealias Entry = GlassticComplicationEntry

    func placeholder(in context: Context) -> GlassticComplicationEntry {
        GlassticComplicationEntry(
            date: Date(),
            elapsed: 12 * 3600, // 12 hours
            zone: .earlyFasting,
            progress: 0.5,
            streak: 5,
            isActive: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GlassticComplicationEntry) -> Void) {
        let store = WatchFastingStore.shared
        let entry = GlassticComplicationEntry(
            date: Date(),
            elapsed: store.elapsed,
            zone: store.activeZone,
            progress: store.currentProgress,
            streak: store.streak,
            isActive: store.activeSession != nil
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GlassticComplicationEntry>) -> Void) {
        let store = WatchFastingStore.shared
        let currentDate = Date()

        var entries: [GlassticComplicationEntry] = []

        if store.activeSession != nil {
            // Generate entries for next hour (updates every minute)
            for minuteOffset in 0..<60 {
                let entryDate = currentDate.addingTimeInterval(Double(minuteOffset * 60))
                let elapsed = store.elapsed + Double(minuteOffset * 60)
                let zone = store.thresholds.zone(for: elapsed)
                let progress = store.thresholds.progress(in: zone, elapsed: elapsed)

                let entry = GlassticComplicationEntry(
                    date: entryDate,
                    elapsed: elapsed,
                    zone: zone,
                    progress: progress,
                    streak: store.streak,
                    isActive: true
                )
                entries.append(entry)
            }
        } else {
            // No active session - show static entry
            let entry = GlassticComplicationEntry(
                date: currentDate,
                elapsed: 0,
                zone: .postMeal,
                progress: 0,
                streak: store.streak,
                isActive: false
            )
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Complication Entry

struct GlassticComplicationEntry: TimelineEntry {
    let date: Date
    let elapsed: TimeInterval
    let zone: FastingZone
    let progress: Double
    let streak: Int
    let isActive: Bool

    var hoursElapsed: Int {
        Int(elapsed / 3600)
    }

    var minutesElapsed: Int {
        Int((elapsed.truncatingRemainder(dividingBy: 3600)) / 60)
    }

    var progressPercentage: Int {
        Int(progress * 100)
    }
}

// MARK: - Complication Views

struct GlassticComplication: Widget {
    let kind: String = "GlassticComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GlassticComplicationProvider()) { entry in
            GlassticComplicationView(entry: entry)
        }
        .configurationDisplayName("Glasstic")
        .description("Track your fasting progress")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryCorner,
            .accessoryInline
        ])
    }
}

struct GlassticComplicationView: View {
    @Environment(\.widgetFamily) var family
    let entry: GlassticComplicationEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            CircularComplicationView(entry: entry)

        case .accessoryRectangular:
            RectangularComplicationView(entry: entry)

        case .accessoryCorner:
            CornerComplicationView(entry: entry)

        case .accessoryInline:
            InlineComplicationView(entry: entry)

        default:
            EmptyView()
        }
    }
}

// MARK: - Circular Gauge

struct CircularComplicationView: View {
    let entry: GlassticComplicationEntry

    var body: some View {
        if entry.isActive {
            ZStack {
                // Progress ring
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(entry.zone.watchColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                // Percentage
                VStack(spacing: 0) {
                    Text("\(entry.progressPercentage)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 10, weight: .semibold))
                }
            }
            .widgetLabel {
                Text("\(entry.hoursElapsed)h \(entry.minutesElapsed)m")
            }
        } else {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 3)

                Image(systemName: "timer")
                    .font(.system(size: 24, weight: .medium))
            }
            .widgetLabel {
                if entry.streak > 0 {
                    Label("\(entry.streak)", systemImage: "flame.fill")
                } else {
                    Text("Ready")
                }
            }
        }
    }
}

// MARK: - Rectangular Full

struct RectangularComplicationView: View {
    let entry: GlassticComplicationEntry

    var body: some View {
        if entry.isActive {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: entry.zone.watchIcon)
                        .font(.system(size: 12, weight: .semibold))
                    Text(entry.zone.shortName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(entry.zone.watchColor)
                }

                Text(timeString)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [entry.zone.watchColor, entry.zone.watchColor.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                HStack(spacing: 4) {
                    ProgressView(value: entry.progress)
                        .tint(entry.zone.watchColor)
                    Text("\(entry.progressPercentage)%")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        } else {
            HStack {
                Image(systemName: "timer")
                    .font(.system(size: 28))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Ready to Fast")
                        .font(.system(size: 13, weight: .semibold))

                    if entry.streak > 0 {
                        Label("\(entry.streak) day streak", systemImage: "flame.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                    } else {
                        Text("Start your journey")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
    }

    private var timeString: String {
        String(format: "%d:%02d", entry.hoursElapsed, entry.minutesElapsed)
    }
}

// MARK: - Corner

struct CornerComplicationView: View {
    let entry: GlassticComplicationEntry

    var body: some View {
        if entry.isActive {
            Text(timeString)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [entry.zone.watchColor, entry.zone.watchColor.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .widgetLabel {
                    ProgressView(value: entry.progress)
                        .tint(entry.zone.watchColor)
                }
        } else {
            Image(systemName: "timer")
                .font(.system(size: 16, weight: .medium))
                .widgetLabel {
                    if entry.streak > 0 {
                        Label("\(entry.streak)", systemImage: "flame.fill")
                    } else {
                        Text("Ready")
                    }
                }
        }
    }

    private var timeString: String {
        String(format: "%d:%02d", entry.hoursElapsed, entry.minutesElapsed)
    }
}

// MARK: - Inline

struct InlineComplicationView: View {
    let entry: GlassticComplicationEntry

    var body: some View {
        if entry.isActive {
            Label {
                Text(timeString + " • \(entry.zone.shortName)")
            } icon: {
                Image(systemName: entry.zone.watchIcon)
            }
        } else {
            if entry.streak > 0 {
                Label("\(entry.streak) day streak", systemImage: "flame.fill")
            } else {
                Label("Ready to fast", systemImage: "timer")
            }
        }
    }

    private var timeString: String {
        String(format: "%d:%02dh", entry.hoursElapsed, entry.minutesElapsed)
    }
}

#Preview("Circular", as: .accessoryCircular) {
    GlassticComplication()
} timeline: {
    GlassticComplicationEntry(
        date: Date(),
        elapsed: 12 * 3600,
        zone: .earlyFasting,
        progress: 0.5,
        streak: 5,
        isActive: true
    )
}

#Preview("Rectangular", as: .accessoryRectangular) {
    GlassticComplication()
} timeline: {
    GlassticComplicationEntry(
        date: Date(),
        elapsed: 16 * 3600,
        zone: .fatBurning,
        progress: 0.75,
        streak: 5,
        isActive: true
    )
}

#Preview("Corner", as: .accessoryCorner) {
    GlassticComplication()
} timeline: {
    GlassticComplicationEntry(
        date: Date(),
        elapsed: 8 * 3600,
        zone: .earlyFasting,
        progress: 0.3,
        streak: 5,
        isActive: true
    )
}
