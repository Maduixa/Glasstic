import SwiftUI

public struct GlassmorphicGauge: View {
    let progress: Double
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let goal: TimeInterval
    let isActive: Bool
    let currentZone: FastingZone
    let estimatedCalories: Double
    
    /// Whether to use Metal-based liquid glass rendering (default: true)
    var useMetalRendering: Bool = true

    public init(
        progress: Double,
        elapsed: TimeInterval,
        remaining: TimeInterval,
        goal: TimeInterval,
        isActive: Bool,
        currentZone: FastingZone = .fedState,
        estimatedCalories: Double = 0,
        useMetalRendering: Bool = true
    ) {
        self.progress = progress
        self.elapsed = elapsed
        self.remaining = remaining
        self.goal = goal
        self.isActive = isActive
        self.currentZone = currentZone
        self.estimatedCalories = estimatedCalories
        self.useMetalRendering = useMetalRendering
    }

    private var accentColor: Color {
        currentZone.color
    }
    
    @State private var isTouched = false

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
                    // MARK: - Metal Liquid Glass Background (when enabled)
                    if useMetalRendering {
                        LiquidGlassSurface(
                            currentZone: currentZone,
                            progress: Float(min(progress, 1.5)),
                            pulseIntensity: Float(currentZone.metabolicMultiplier - 1.0) * 10,
                            interactionEnabled: true
                        ) { _ in
                            // Haptic feedback on touch
                            let generator = UIImpactFeedbackGenerator(style: .soft)
                            generator.impactOccurred()
                            
                            withAnimation(.easeInOut(duration: 0.1)) {
                                isTouched = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isTouched = false
                                }
                            }
                        }
                        .frame(width: size, height: size)
                        .clipShape(Circle())
                        .scaleEffect(isTouched ? 0.98 : 1.0)
                        .opacity(0.85) // Blend with overlay
                    }
                    
                    // Background track
                    Circle()
                        .stroke(trackGradient, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 6)

                    // Glass highlight on track
                    Circle()
                        .stroke(
                            Color.white.opacity(0.3),
                            style: StrokeStyle(lineWidth: ringWidth * 0.28, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .blendMode(.screen)
                        .opacity(0.35)

                    // Top highlight arc
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

                    // Bottom shadow arc
                    Circle()
                        .trim(from: 0.52, to: 0.94)
                        .stroke(
                            Color.black.opacity(0.08),
                            style: StrokeStyle(lineWidth: ringWidth * 0.45, lineCap: .round)
                        )
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))

                    // Progress ring with zone-colored gradient
                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(progressGradient, style: StrokeStyle(lineWidth: ringWidth, lineCap: .round))
                        .frame(width: ringDiameter, height: ringDiameter)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: accentColor.opacity(0.35), radius: 10, x: 0, y: 6)
                        .animation(.easeInOut(duration: 0.45), value: clampedProgress)

                    // Progress highlight
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

                    // Zone indicator cap
                    if clampedProgress > 0 {
                        ZStack {
                            Circle()
                                .fill(.white)
                                .shadow(color: accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                            Circle()
                                .stroke(accentColor.opacity(0.4), lineWidth: 2)
                            Text(currentZone.emoji)
                                .font(.system(size: ringWidth * 0.6))
                                .shadow(color: .black.opacity(0.12), radius: 1, x: 0, y: 1)
                        }
                        .frame(width: ringWidth * 1.15, height: ringWidth * 1.15)
                        .position(capPoint)
                    }

                    // Inner circle
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

                    // Center content
                    VStack(spacing: 8) {
                        Text("Elapsed (\(progressPercent)%)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.black.opacity(0.45))

                        Text(timeString(from: elapsedSeconds))
                            .font(.system(size: size * 0.16, weight: .semibold, design: .rounded))
                            .foregroundStyle(counterGradient)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                            .animation(.smooth(duration: 0.4), value: elapsedSeconds)
                            .shadow(color: accentColor.opacity(0.25), radius: 6, x: 0, y: 3)

                        // Zone indicator pill
                        ZonePill(zone: currentZone, isActive: isActive)

                        // Calories if active
                        if isActive && estimatedCalories > 0 {
                            Text("~\(Int(estimatedCalories)) kcal")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color.black.opacity(0.4))
                        }
                    }
                }
                .frame(width: size, height: size)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 360)
        }
    }

    // MARK: - Gradients

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

    // MARK: - Computed Values

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    private var elapsedSeconds: Int {
        max(Int(elapsed.rounded(.down)), 0)
    }

    private var progressPercent: Int {
        Int((clampedProgress * 100).rounded())
    }

    private func timeString(from seconds: Int) -> String {
        let totalSeconds = max(seconds, 0)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }
}

// MARK: - Zone Pill

private struct ZonePill: View {
    let zone: FastingZone
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(zone.color)
            Text(isActive ? zone.shortName : "READY")
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
                .stroke(zone.color.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - Zone Progress Card

public struct ZoneProgressCard: View {
    let currentZone: FastingZone
    let zoneProgress: Double
    let timeToNextZone: TimeInterval?

    public init(currentZone: FastingZone, zoneProgress: Double, timeToNextZone: TimeInterval?) {
        self.currentZone = currentZone
        self.zoneProgress = zoneProgress
        self.timeToNextZone = timeToNextZone
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(currentZone.emoji)
                    .font(.title2)
                Text(currentZone.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                if let nextZone = currentZone.nextZone {
                    Text("Next: \(nextZone.emoji)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
            }

            Text(currentZone.metabolicDescription)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(2)

            // Zone progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                    Capsule()
                        .fill(currentZone.color)
                        .frame(width: geo.size.width * min(zoneProgress, 1))
                }
            }
            .frame(height: 6)

            if let time = timeToNextZone, let nextZone = currentZone.nextZone {
                Text("\(formatTime(time)) until \(nextZone.name)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .liquidGlass(
                    .regular
                        .tint(currentZone.color.opacity(0.3))
                        .cornerRadius(22),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        )
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - All Zones Overview

public struct ZonesOverviewCard: View {
    let currentZone: FastingZone
    let elapsed: TimeInterval

    public init(currentZone: FastingZone, elapsed: TimeInterval) {
        self.currentZone = currentZone
        self.elapsed = elapsed
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Fasting Zones")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            VStack(spacing: 8) {
                ForEach(FastingZone.allCases) { zone in
                    HStack(spacing: 12) {
                        Text(zone.emoji)
                            .font(.body)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(zone.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(zone == currentZone ? .white : .white.opacity(0.6))
                            Text("\(Int(zone.startHour))h - \(zone.endHour.isFinite ? "\(Int(zone.endHour))h" : "∞")")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }

                        Spacer()

                        // Status indicator
                        if zone.rawValue < currentZone.rawValue {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if zone == currentZone {
                            Circle()
                                .fill(zone.color)
                                .frame(width: 10, height: 10)
                                .overlay(
                                    Circle()
                                        .stroke(.white.opacity(0.5), lineWidth: 2)
                                )
                        } else {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                .frame(width: 10, height: 10)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .liquidGlass(
                    .regular
                        .tint(.white)
                        .cornerRadius(22),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
        )
    }
}
