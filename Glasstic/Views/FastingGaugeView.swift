import SwiftUI

struct FastingGaugeView: View {
    var elapsed: TimeInterval
    var thresholds: FastingThresholds
    var activeZone: FastingZone
    var accent: Color

    private var elapsedHours: Double {
        elapsed / 3600
    }

    private var totalReferenceHours: Double {
        max(thresholds.fatBurningEndHours + 6, elapsedHours + 2)
    }

    private var segments: [ZoneSegment] {
        var cursor: Double = 0
        let zones: [FastingZone] = [.postMeal, .earlyFasting, .fatBurning, .deepKetosis]
        return zones.map { zone in
            let end: Double
            switch zone {
            case .postMeal:
                end = thresholds.postMealEndHours
            case .earlyFasting:
                end = thresholds.earlyFastingEndHours
            case .fatBurning:
                end = thresholds.fatBurningEndHours
            case .deepKetosis:
                end = totalReferenceHours
            }
            defer { cursor = max(end, cursor) }
            return ZoneSegment(
                zone: zone,
                start: cursor / totalReferenceHours,
                end: max(end, cursor) / totalReferenceHours
            )
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Fasting Zones")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(.primary)

            GeometryReader { geometry in
                let size = min(geometry.size.width, geometry.size.height)
                ZStack {
                    ForEach(segments) { segment in
                        Circle()
                            .trim(from: segment.startFraction, to: segment.endFraction)
                            .stroke(
                                style: StrokeStyle(lineWidth: 18, lineCap: .round)
                            )
                            .fill(zoneColor(for: segment.zone).opacity(0.18))
                            .rotationEffect(.degrees(-90))
                    }

                    ForEach(segments) { segment in
                        Circle()
                            .trim(
                                from: segment.startFraction,
                                to: segment.trimmedProgress(for: elapsed, thresholds: thresholds)
                            )
                            .stroke(
                                style: StrokeStyle(lineWidth: segment.zone == activeZone ? 20 : 16, lineCap: .round)
                            )
                            .fill(progressGradient(for: segment.zone))
                            .shadow(color: accent.opacity(segment.zone == activeZone ? 0.5 : 0.12), radius: segment.zone == activeZone ? 18 : 8, x: 0, y: 8)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.4), value: elapsed)
                    }

                    VStack(spacing: 8) {
                        Text(TimeFormatter.shared.string(from: elapsed))
                            .font(.system(size: 34, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(accent)
                        Text(activeZone.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(zoneWindowDescription(for: activeZone))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: size, height: size)
            }
            .frame(height: 260)

            VStack(spacing: 12) {
                ForEach(segments) { segment in
                    HStack {
                        Capsule()
                            .fill(zoneColor(for: segment.zone))
                            .frame(width: 36, height: 12)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                        Text(segment.zone.displayName)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(zoneRangeDescription(for: segment.zone))
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .opacity(segment.zone == activeZone ? 1.0 : 0.7)
                }
            }
        }
    }

    private func zoneColor(for zone: FastingZone) -> Color {
        switch zone {
        case .postMeal:
            return Color.white.opacity(0.7)
        case .earlyFasting:
            return Color.white.opacity(0.9)
        case .fatBurning:
            return accent.opacity(0.8)
        case .deepKetosis:
            return accent
        }
    }

    private func progressGradient(for zone: FastingZone) -> LinearGradient {
        let base = zoneColor(for: zone)
        return LinearGradient(
            colors: [base.opacity(0.5), base],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func zoneWindowDescription(for zone: FastingZone) -> String {
        switch zone {
        case .postMeal:
            return "0 - \(Int(thresholds.postMealEndHours))h"
        case .earlyFasting:
            return "\(Int(thresholds.postMealEndHours)) - \(Int(thresholds.earlyFastingEndHours))h"
        case .fatBurning:
            return "\(Int(thresholds.earlyFastingEndHours)) - \(Int(thresholds.fatBurningEndHours))h"
        case .deepKetosis:
            return "\(Int(thresholds.fatBurningEndHours))+ hours"
        }
    }

    private func zoneRangeDescription(for zone: FastingZone) -> String {
        zoneWindowDescription(for: zone)
    }
}

private struct ZoneSegment: Identifiable {
    var id: String { zone.id }
    let zone: FastingZone
    let start: Double
    let end: Double

    var startFraction: CGFloat {
        CGFloat(start)
    }

    var endFraction: CGFloat {
        CGFloat(end)
    }

    func trimmedProgress(for elapsed: TimeInterval, thresholds: FastingThresholds) -> CGFloat {
        let total = end - start
        guard total > 0 else {
            return CGFloat(end)
        }
        let progress = thresholds.progress(in: zone, elapsed: elapsed)
        return CGFloat(start + total * progress)
    }
}
