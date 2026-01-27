import SwiftUI

public struct GlassmorphicGauge: View {
    let progress: Double
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let goal: TimeInterval
    let isActive: Bool
    let accentColor: Color

    public init(
        progress: Double,
        elapsed: TimeInterval,
        remaining: TimeInterval,
        goal: TimeInterval,
        isActive: Bool,
        accentColor: Color = .cyan
    ) {
        self.progress = progress
        self.elapsed = elapsed
        self.remaining = remaining
        self.goal = goal
        self.isActive = isActive
        self.accentColor = accentColor
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                let ringDiameter = size * 0.94
                let ringWidth = max(size * 0.085, 20)
                let innerSize = size * 0.78

                ZStack {
                    // Track ring with glass highlight
                    Circle()
                        .stroke(
                            Color.white.opacity(0.12),
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)

                    // Glass highlight on track
                    Circle()
                        .trim(from: 0.05, to: 0.35)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: ringWidth * 0.6, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .blendMode(.plusLighter)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(
                            progressGradient,
                            style: StrokeStyle(lineWidth: ringWidth, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: accentColor.opacity(0.4), radius: 12, x: 0, y: 6)
                        .animation(.easeInOut(duration: 0.45), value: clampedProgress)

                    // Progress ring highlight
                    if clampedProgress > 0.02 {
                        Circle()
                            .trim(from: 0, to: clampedProgress)
                            .stroke(
                                Color.white.opacity(0.4),
                                style: StrokeStyle(lineWidth: ringWidth * 0.35, lineCap: .round)
                            )
                            .frame(width: ringDiameter, height: ringDiameter)
                            .rotationEffect(.degrees(-90))
                            .blendMode(.plusLighter)
                    }

                    // Knob at progress end
                    if clampedProgress > 0 {
                        knobView(ringDiameter: ringDiameter, ringWidth: ringWidth, size: size)
                    }

                    // Center content with glass effect and refraction
                    centerContent(innerSize: innerSize, containerSize: size, time: time)
                }
                .frame(width: size, height: size)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 360)
    }

    private func knobView(ringDiameter: CGFloat, ringWidth: CGFloat, size: CGFloat) -> some View {
        let angle = clampedProgress * 360 - 90
        let radius = ringDiameter / 2
        let capPoint = CGPoint(
            x: size / 2 + CGFloat(cos(angle * .pi / 180)) * radius,
            y: size / 2 + CGFloat(sin(angle * .pi / 180)) * radius
        )

        return Text(zoneEmoji)
            .font(.system(size: ringWidth * 0.7))
            .frame(width: ringWidth * 1.3, height: ringWidth * 1.3)
            .background(.white, in: .circle)
            .overlay(Circle().stroke(accentColor.opacity(0.4), lineWidth: 2))
            .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
            .position(capPoint)
    }

    private func centerContent(innerSize: CGFloat, containerSize: CGFloat, time: TimeInterval) -> some View {
        let phase = time * 0.3

        return ZStack {
            // Glass base
            Circle()
                .fill(.clear)
                .frame(width: innerSize, height: innerSize)
                .glassEffect(.regular, in: .circle)

            // Refraction caustics inside
            ZStack {
                RadialGradient(
                    colors: [Color.white.opacity(0.35), .clear],
                    center: UnitPoint(
                        x: 0.25 + sin(phase * 0.5) * 0.08,
                        y: 0.2 + cos(phase * 0.4) * 0.06
                    ),
                    startRadius: 0,
                    endRadius: innerSize * 0.4
                )

                RadialGradient(
                    colors: [accentColor.opacity(0.2), .clear],
                    center: UnitPoint(
                        x: 0.75 - sin(phase * 0.4) * 0.06,
                        y: 0.7 + cos(phase * 0.35) * 0.05
                    ),
                    startRadius: 0,
                    endRadius: innerSize * 0.35
                )
            }
            .frame(width: innerSize, height: innerSize)
            .clipShape(Circle())
            .blendMode(.plusLighter)

            // Content
            VStack(spacing: 10) {
                Text("Elapsed (\(progressPercent)%)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(timeString(from: elapsedSeconds))
                    .font(.system(size: containerSize * 0.16, weight: .semibold, design: .rounded))
                    .foregroundStyle(accentColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.4), value: elapsedSeconds)
                    .shadow(color: accentColor.opacity(0.3), radius: 8)

                StatusPill(title: statusLabel, tint: accentColor)
            }
        }
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [
                accentColor.opacity(0.6),
                accentColor,
                accentColor.opacity(0.8)
            ],
            center: .center
        )
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var elapsedSeconds: Int {
        max(Int(elapsed.rounded(.down)), 0)
    }

    private var progressPercent: Int {
        Int((clampedProgress * 100).rounded())
    }

    private var statusLabel: String {
        guard isActive else { return "READY" }
        return currentZone.title
    }

    private func timeString(from seconds: Int) -> String {
        let totalSeconds = max(seconds, 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    private var zoneEmoji: String {
        currentZone.emoji
    }

    private var currentZone: GaugeZone {
        let hours = max(elapsed, 0) / 3600
        if hours < 4 { return .postMeal }
        if hours < 12 { return .earlyFasting }
        if hours < 18 { return .fatBurning }
        return .deepFast
    }

    private enum GaugeZone {
        case postMeal, earlyFasting, fatBurning, deepFast

        var title: String {
            switch self {
            case .postMeal: return "POST-MEAL"
            case .earlyFasting: return "EARLY FAST"
            case .fatBurning: return "FAT BURN"
            case .deepFast: return "DEEP FAST"
            }
        }

        var emoji: String {
            switch self {
            case .postMeal: return "🍽️"
            case .earlyFasting: return "🌤️"
            case .fatBurning: return "🔥"
            case .deepFast: return "🌙"
            }
        }
    }
}

private struct StatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .kerning(0.7)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .glassEffect(.regular.tint(tint), in: .capsule)
    }
}
