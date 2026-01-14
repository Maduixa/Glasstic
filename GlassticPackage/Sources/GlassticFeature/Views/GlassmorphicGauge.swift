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
        GlassEffectContainer(spacing: 12) {
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                let ringDiameter = size * 0.94
                let ringWidth = max(size * 0.085, 20)
                let ringRadius = ringDiameter / 2
                let innerSize = size * 0.81
                let angle = clampedProgress * 360 - 90
                let capPoint = CGPoint(
                    x: size / 2 + CGFloat(cos(angle * .pi / 180)) * ringRadius,
                    y: size / 2 + CGFloat(sin(angle * .pi / 180)) * ringRadius
                )

                ZStack {
                    Circle()
                        .stroke(trackGradient, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 6)

                    Circle()
                        .stroke(
                            Color.white.opacity(0.3),
                            style: StrokeStyle(lineWidth: ringWidth * 0.28, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .blendMode(.screen)
                        .opacity(0.35)

                    Circle()
                        .trim(from: 0.06, to: 0.42)
                        .stroke(
                            glassHighlightGradient,
                            style: StrokeStyle(lineWidth: ringWidth * 0.55, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .blendMode(.screen)
                        .opacity(0.65)

                    Circle()
                        .trim(from: 0.52, to: 0.94)
                        .stroke(
                            Color.black.opacity(0.08),
                            style: StrokeStyle(lineWidth: ringWidth * 0.45, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))

                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(progressGradient, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
                        .animation(.easeInOut(duration: 0.45), value: clampedProgress)

                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(
                            Color.white.opacity(0.55),
                            style: StrokeStyle(lineWidth: ringWidth * 0.35, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .blendMode(.screen)
                        .opacity(0.7)

                    if clampedProgress > 0 {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            Circle()
                                .stroke(accentColor.opacity(0.4), lineWidth: 2)
                            Text(zoneEmoji)
                                .font(.system(size: ringWidth * 0.6))
                                .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                        }
                        .frame(width: ringWidth * 1.15, height: ringWidth * 1.15)
                        .position(capPoint)
                    }

                    Circle()
                        .fill(Color.white.opacity(0.95))
                        .frame(width: innerSize, height: innerSize)
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 6)
                        .overlay(
                            Circle()
                                .stroke(.white.opacity(0.8), lineWidth: 1)
                        )
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.35), lineWidth: 2)
                                .blendMode(.screen)
                                .padding(innerSize * 0.04)
                        )
                        .overlay(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            .white.opacity(0.6),
                                            .clear
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .opacity(0.6)
                        )

                    VStack(spacing: 10) {
                        Text("Elapsed time (\(progressPercent)%)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.45))

                        Text(timeString(from: elapsedSeconds))
                            .font(.system(size: size * 0.175, weight: .semibold, design: .rounded))
                            .foregroundStyle(counterGradient)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.smooth(duration: 0.4), value: elapsedSeconds)
                            .shadow(color: accentColor.opacity(0.25), radius: 6, x: 0, y: 3)

                        StatusPill(title: statusLabel, tint: accentColor)
                    }
                }
                .frame(width: size, height: size)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 360)
        }
    }

    private var trackGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.4),
                Color.white.opacity(0.12),
                Color.white.opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var glassHighlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.7),
                Color.white.opacity(0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var progressGradient: AngularGradient {
        AngularGradient(
            colors: [
                accentColor.opacity(0.7),
                accentColor,
                accentColor.opacity(0.5),
                accentColor.opacity(0.8)
            ],
            center: .center
        )
    }

    private var counterGradient: LinearGradient {
        LinearGradient(
            colors: [
                accentColor.opacity(0.95),
                Color.black.opacity(0.72),
                accentColor.opacity(0.85)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
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
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private var zoneEmoji: String {
        currentZone.emoji
    }

    private var currentZone: GaugeZone {
        let hours = max(elapsed, 0) / 3600
        if hours < 4 {
            return .postMeal
        }
        if hours < 12 {
            return .earlyFasting
        }
        if hours < 18 {
            return .fatBurning
        }
        return .deepFast
    }

    private enum GaugeZone {
        case postMeal
        case earlyFasting
        case fatBurning
        case deepFast

        var title: String {
            switch self {
            case .postMeal:
                return "POST-MEAL"
            case .earlyFasting:
                return "EARLY FAST"
            case .fatBurning:
                return "FAT BURN"
            case .deepFast:
                return "DEEP FAST"
            }
        }

        var emoji: String {
            switch self {
            case .postMeal:
                return "\u{1F37D}\u{FE0F}"
            case .earlyFasting:
                return "\u{1F324}\u{FE0F}"
            case .fatBurning:
                return "\u{1F525}"
            case .deepFast:
                return "\u{1F319}"
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
                .foregroundStyle(Color.black.opacity(0.55))
                .kerning(0.7)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.8))
        )
        .overlay(
            Capsule()
                .stroke(tint.opacity(0.35), lineWidth: 1)
        )
    }
}
