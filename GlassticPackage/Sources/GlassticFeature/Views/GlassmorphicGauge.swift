import SwiftUI

public struct GlassmorphicGauge: View {
    let progress: Double
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let goal: TimeInterval
    let isActive: Bool
    let accentColor: Color

    private let lineWidth: CGFloat = 20

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
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [accentColor.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: 180
                        )
                    )
                    .blur(radius: 12)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.05),
                                Color.black.opacity(0.32)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .liquidGlass(
                        .regular
                            .tint(.white)
                            .cornerRadius(200),
                        in: Circle()
                    )

                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1.2)

                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                accentColor.opacity(0.25),
                                accentColor.opacity(0.85),
                                accentColor.opacity(0.45)
                            ],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: accentColor.opacity(0.45), radius: 10, x: 0, y: 0)
                    .animation(.snappy(duration: 0.8), value: clampedProgress)

                VStack(spacing: 10) {
                    Text(timeString(from: elapsed))
                        .font(.system(size: 52, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                        .monospacedDigit()

                Text(isActive ? "Elapsed" : "Ready")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)

                Text("\(progressPercent)% of \(goalText)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    HStack(spacing: 8) {
                        GaugeChip(title: "Remaining", value: timeString(from: remaining))
                        GaugeChip(title: "Goal", value: goalText)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.black.opacity(0.28))
                        .liquidGlass(
                            .regular
                                .tint(.white)
                                .cornerRadius(22),
                            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                        )
                }
            }
            .frame(width: 300, height: 300)
        }
    }

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var progressPercent: Int {
        Int((clampedProgress * 100).rounded())
    }

    private var goalText: String {
        let hours = Int(goal / 3600)
        return "\(hours)h"
    }

    private func timeString(from interval: TimeInterval) -> String {
        let totalMinutes = max(Int(interval) / 60, 0)
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        return String(format: "%02d:%02d", hours, minutes)
    }
}

private struct GaugeChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .kerning(0.8)

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.25))
        )
        .liquidGlass(
            .regular
                .tint(.white)
                .cornerRadius(999),
            in: Capsule()
        )
    }
}
