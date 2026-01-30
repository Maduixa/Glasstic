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
                
                // Zone milestone markers around the ring
                zoneMarkers(
                    ringDiameter: ringDiameter,
                    ringWidth: ringWidth,
                    containerSize: size
                )
                
                // Glowing progress ring with zone-based gradient
                ZoneGradientProgressRing(
                    progress: clampedProgress,
                    diameter: ringDiameter,
                    lineWidth: ringWidth,
                    zone: currentZone
                )
                
                // Glowing knob at progress end
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
                    accentColor: zoneColor,
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
    
    // MARK: - Zone Markers
    
    private func zoneMarkers(ringDiameter: CGFloat, ringWidth: CGFloat, containerSize: CGFloat) -> some View {
        ZoneMarkersView(
            ringDiameter: ringDiameter,
            containerSize: containerSize,
            elapsed: elapsed,
            goal: goal
        )
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
            // Outer glow
            Circle()
                .fill(zoneColor.opacity(0.4))
                .frame(width: ringWidth * 2.2, height: ringWidth * 2.2)
                .blur(radius: 12)
            
            // Inner glow
            Circle()
                .fill(zoneColor.opacity(0.6))
                .frame(width: ringWidth * 1.5, height: ringWidth * 1.5)
                .blur(radius: 6)
            
            // Knob body
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, zoneColor.opacity(0.3)],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: ringWidth
                    )
                )
                .frame(width: ringWidth * 1.2, height: ringWidth * 1.2)
                .overlay {
                    Circle()
                        .stroke(zoneColor, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
            
            // Current zone emoji
            Text(zoneEmoji)
                .font(.system(size: ringWidth * 0.55))
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
                .foregroundStyle(zoneColor)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.smooth(duration: 0.4), value: elapsedSeconds)
                .shadow(color: zoneColor.opacity(0.4), radius: 10)
                .shadow(color: zoneColor.opacity(0.2), radius: 4)

            StatusPill(title: statusLabel, tint: zoneColor)
        }
        .animation(.easeInOut(duration: 0.5), value: currentZone)
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
    
    private var zoneColor: Color {
        currentZone.color
    }

    private var currentZone: GaugeZone {
        let hours = max(elapsed, 0) / 3600
        if hours < 4 { return .postMeal }
        if hours < 12 { return .earlyFasting }
        if hours < 18 { return .fatBurning }
        return .deepFast
    }
}

// MARK: - Gauge Zone

enum GaugeZone: Hashable {
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
    
    var color: Color {
        switch self {
        case .postMeal: return .orange
        case .earlyFasting: return .yellow
        case .fatBurning: return .green
        case .deepFast: return .cyan
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .postMeal:
            return [.orange, .yellow, .orange.opacity(0.8)]
        case .earlyFasting:
            return [.yellow, .green, .yellow.opacity(0.8)]
        case .fatBurning:
            return [.green, .cyan, .green.opacity(0.8)]
        case .deepFast:
            return [.cyan, .purple, .pink, .cyan.opacity(0.8)]
        }
    }
}

// MARK: - Zone Threshold

enum ZoneThreshold: String, CaseIterable, Identifiable {
    case postMealEnd
    case earlyFastingEnd
    case fatBurningEnd
    case deepKetosis
    
    var id: String { rawValue }
    
    var hours: Double {
        switch self {
        case .postMealEnd: return 4
        case .earlyFastingEnd: return 12
        case .fatBurningEnd: return 18
        case .deepKetosis: return 24
        }
    }
    
    var emoji: String {
        switch self {
        case .postMealEnd: return "🍽️"
        case .earlyFastingEnd: return "🌤️"
        case .fatBurningEnd: return "🔥"
        case .deepKetosis: return "🌙"
        }
    }
    
    var zone: GaugeZone {
        switch self {
        case .postMealEnd: return .postMeal
        case .earlyFastingEnd: return .earlyFasting
        case .fatBurningEnd: return .fatBurning
        case .deepKetosis: return .deepFast
        }
    }
}

// MARK: - Zone Markers View

private struct ZoneMarkersView: View {
    let ringDiameter: CGFloat
    let containerSize: CGFloat
    let elapsed: TimeInterval
    let goal: TimeInterval
    
    private var radius: CGFloat { ringDiameter / 2 }
    private var elapsedHours: Double { elapsed / 3600 }
    private var goalHours: Double { goal / 3600 }
    
    // Determine which zone we're currently in
    private var currentZoneIndex: Int {
        if elapsedHours < 4 { return 0 }      // post-meal
        if elapsedHours < 12 { return 1 }     // early fasting
        if elapsedHours < 18 { return 2 }     // fat burning
        return 3                               // deep ketosis
    }
    
    var body: some View {
        ZStack {
            markerView(for: .postMealEnd, index: 0)
            markerView(for: .earlyFastingEnd, index: 1)
            markerView(for: .fatBurningEnd, index: 2)
            markerView(for: .deepKetosis, index: 3)
        }
    }
    
    @ViewBuilder
    private func markerView(for threshold: ZoneThreshold, index: Int) -> some View {
        // Show marker if: we're in this zone (current target) OR we've surpassed it
        let isVisible = index <= currentZoneIndex
        let isReached = elapsedHours >= threshold.hours
        
        if threshold.hours <= goalHours && isVisible {
            let markerProgress = threshold.hours / goalHours
            let angleDegrees = markerProgress * 360 - 90
            let angleRadians = angleDegrees * .pi / 180
            let x = containerSize / 2 + cos(angleRadians) * radius
            let y = containerSize / 2 + sin(angleRadians) * radius
            
            ZoneMarker(
                emoji: threshold.emoji,
                isReached: isReached,
                zone: threshold.zone
            )
            .position(x: x, y: y)
        }
    }
}

// MARK: - Zone Marker

private struct ZoneMarker: View {
    let emoji: String
    let isReached: Bool
    let zone: GaugeZone
    
    var body: some View {
        Text(emoji)
            .font(.system(size: 14))
            .frame(width: 26, height: 26)
            .background {
                Circle()
                    .fill(isReached ? zone.color.opacity(0.2) : .black.opacity(0.3))
                    .overlay {
                        Circle()
                            .stroke(
                                isReached ? zone.color : .white.opacity(0.2),
                                lineWidth: isReached ? 2 : 1
                            )
                    }
            }
            .shadow(color: isReached ? zone.color.opacity(0.5) : .clear, radius: 6)
            .opacity(isReached ? 1.0 : 0.5)
            .scaleEffect(isReached ? 1.0 : 0.85)
            .animation(.bouncy(duration: 0.4), value: isReached)
    }
}

// MARK: - Zone Gradient Progress Ring

private struct ZoneGradientProgressRing: View {
    let progress: Double
    let diameter: CGFloat
    let lineWidth: CGFloat
    let zone: GaugeZone
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    zone.color.opacity(0.3),
                    style: StrokeStyle(lineWidth: lineWidth + 14, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
                .blur(radius: 10)
            
            // Main progress arc with zone gradient
            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(
                    AngularGradient(
                        colors: zone.gradientColors,
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: diameter, height: diameter)
                .rotationEffect(.degrees(-90))
            
            // Inner bright highlight
            if clampedProgress > 0.02 {
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.6), .white.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: lineWidth * 0.3, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(-90))
                    .blendMode(.plusLighter)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: zone)
        .animation(.easeInOut(duration: 0.5), value: clampedProgress)
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
