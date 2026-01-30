import SwiftUI

public struct GlassmorphicGauge: View {
    let progress: Double
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let goal: TimeInterval
    let isActive: Bool
    let accentColor: Color
    
    @StateObject private var motion = MotionProvider()
    @Environment(\.scenePhase) private var scenePhase

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
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let ringDiameter = size * 0.92
            let ringWidth = max(size * 0.075, 18)
            let innerSize = size * 0.72
            
            ZStack {
                // Glass ring track with parallax highlight
                GlassRingTrack(
                    diameter: ringDiameter,
                    lineWidth: ringWidth,
                    tilt: motion.normalizedTilt
                )
                
                // Prismatic edge on ring
                PrismaticEdge(
                    diameter: ringDiameter + ringWidth,
                    lineWidth: 1.5,
                    intensity: 0.08
                )
                
                // Inner prismatic edge
                PrismaticEdge(
                    diameter: ringDiameter - ringWidth,
                    lineWidth: 1,
                    intensity: 0.06
                )
                
                // Glowing progress ring
                GlowingProgressRing(
                    progress: clampedProgress,
                    diameter: ringDiameter,
                    lineWidth: ringWidth,
                    accentColor: accentColor
                )
                
                // Knob at progress end
                if clampedProgress > 0.01 {
                    progressKnob(
                        ringDiameter: ringDiameter,
                        ringWidth: ringWidth,
                        containerSize: size
                    )
                }
                
                // Glass center disc with caustics and content
                GlassCenterDisc(
                    size: innerSize,
                    accentColor: accentColor,
                    tilt: motion.normalizedTilt
                ) {
                    centerContent(containerSize: size)
                }
            }
            .frame(width: size, height: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 360)
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: motion.start()
            case .inactive, .background: motion.stop()
            @unknown default: motion.stop()
            }
        }
    }
    
    // MARK: - Progress Knob
    
    private func progressKnob(ringDiameter: CGFloat, ringWidth: CGFloat, containerSize: CGFloat) -> some View {
        let angle = clampedProgress * 360 - 90
        let radius = ringDiameter / 2
        let position = CGPoint(
            x: containerSize / 2 + cos(angle * .pi / 180) * radius,
            y: containerSize / 2 + sin(angle * .pi / 180) * radius
        )
        
        return ZStack {
            // Glow behind knob
            Circle()
                .fill(accentColor.opacity(0.5))
                .frame(width: ringWidth * 1.8, height: ringWidth * 1.8)
                .blur(radius: 8)
            
            // Knob with emoji
            Text(zoneEmoji)
                .font(.system(size: ringWidth * 0.65))
                .frame(width: ringWidth * 1.25, height: ringWidth * 1.25)
                .background {
                    Circle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
                }
                .overlay {
                    Circle()
                        .stroke(accentColor.opacity(0.5), lineWidth: 2)
                }
        }
        .position(position)
    }
    
    // MARK: - Center Content
    
    private func centerContent(containerSize: CGFloat) -> some View {
        VStack(spacing: 8) {
            Text("Elapsed (\(progressPercent)%)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(timeString(from: elapsedSeconds))
                .font(.system(size: containerSize * 0.14, weight: .bold, design: .rounded))
                .foregroundStyle(accentColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.4), value: elapsedSeconds)
                .shadow(color: accentColor.opacity(0.4), radius: 10)
                .shadow(color: accentColor.opacity(0.2), radius: 4)

            StatusPill(title: statusLabel, tint: accentColor)
        }
    }
    
    // MARK: - Computed Properties

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

// MARK: - Status Pill

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
