import SwiftUI

public struct GlassmorphicGauge: View {
    @Environment(AppTheme.self) private var theme

    let progress: Double
    let elapsed: TimeInterval
    let remaining: TimeInterval
    let goal: TimeInterval
    let isActive: Bool

    public init(
        progress: Double,
        elapsed: TimeInterval,
        remaining: TimeInterval,
        goal: TimeInterval,
        isActive: Bool
    ) {
        self.progress = progress
        self.elapsed = elapsed
        self.remaining = remaining
        self.goal = goal
        self.isActive = isActive
    }

    // MARK: - Zone geometry

    private struct ZoneArc: Identifiable {
        let zone: GaugeZone
        let start: Double
        let end: Double
        var id: GaugeZone { zone }
    }

    private struct ZoneBoundary: Identifiable {
        let zone: GaugeZone
        let fraction: Double
        var id: GaugeZone { zone }
    }

    private var zoneArcs: [ZoneArc] {
        guard goal > 0 else { return [] }
        var arcs: [ZoneArc] = []
        var cursor: Double = 0
        for zone in GaugeZone.allCases {
            let zoneEnd: Double
            if let endHours = zone.endHours {
                zoneEnd = min((endHours * 3600) / goal, 1.0)
            } else {
                zoneEnd = 1.0
            }
            let arcEnd = min(zoneEnd, clampedProgress)
            if arcEnd > cursor + 0.001 {
                arcs.append(ZoneArc(zone: zone, start: cursor, end: arcEnd))
            }
            cursor = zoneEnd
            if cursor >= clampedProgress { break }
        }
        return arcs
    }

    private var zoneBoundaries: [ZoneBoundary] {
        guard goal > 0 else { return [] }
        return GaugeZone.allCases.compactMap { zone in
            guard let endHours = zone.endHours else { return nil }
            let fraction = min((endHours * 3600) / goal, 1.0)
            guard fraction < 1.0 else { return nil }
            return ZoneBoundary(zone: zone, fraction: fraction)
        }
    }

    // MARK: - Body

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

                    // Zone-colored progress arcs
                    ForEach(zoneArcs) { arc in
                        Circle()
                            .trim(from: arc.start, to: arc.end)
                            .stroke(
                                arc.zone.color(from: theme.zones),
                                style: StrokeStyle(lineWidth: ringWidth, lineCap: .butt)
                            )
                            .frame(width: ringDiameter, height: ringDiameter)
                            .rotationEffect(.degrees(-90))
                    }
                    .shadow(color: currentZoneColor.opacity(0.4), radius: 12, x: 0, y: 6)
                    .animation(.easeInOut(duration: 0.45), value: clampedProgress)

                    // Round caps at start and tip
                    if clampedProgress > 0.005 {
                        // Start cap
                        capDot(
                            at: 0,
                            color: GaugeZone.postMeal.color(from: theme.zones),
                            ringDiameter: ringDiameter,
                            ringWidth: ringWidth,
                            size: size
                        )
                        // Tip cap
                        capDot(
                            at: clampedProgress,
                            color: currentZoneColor,
                            ringDiameter: ringDiameter,
                            ringWidth: ringWidth,
                            size: size
                        )
                    }

                    // Progress ring highlight
                    if clampedProgress > 0.02 {
                        ForEach(zoneArcs) { arc in
                            Circle()
                                .trim(from: arc.start, to: arc.end)
                                .stroke(
                                    Color.white.opacity(0.4),
                                    style: StrokeStyle(lineWidth: ringWidth * 0.35, lineCap: .butt)
                                )
                                .frame(width: ringDiameter, height: ringDiameter)
                                .rotationEffect(.degrees(-90))
                                .blendMode(.plusLighter)
                        }
                    }

                    // Milestone markers at zone boundaries
                    ForEach(zoneBoundaries) { boundary in
                        if clampedProgress > boundary.fraction + 0.01 {
                            milestoneMarker(
                                zone: boundary.zone,
                                fraction: boundary.fraction,
                                ringDiameter: ringDiameter,
                                ringWidth: ringWidth,
                                size: size
                            )
                        }
                    }

                    // Leading knob at progress tip
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

    // MARK: - Ring helpers

    private func capDot(
        at fraction: Double,
        color: Color,
        ringDiameter: CGFloat,
        ringWidth: CGFloat,
        size: CGFloat
    ) -> some View {
        let angle = fraction * 360 - 90
        let radius = ringDiameter / 2
        let point = CGPoint(
            x: size / 2 + CGFloat(cos(angle * .pi / 180)) * radius,
            y: size / 2 + CGFloat(sin(angle * .pi / 180)) * radius
        )
        return Circle()
            .fill(color)
            .frame(width: ringWidth, height: ringWidth)
            .position(point)
    }

    private func milestoneMarker(
        zone: GaugeZone,
        fraction: Double,
        ringDiameter: CGFloat,
        ringWidth: CGFloat,
        size: CGFloat
    ) -> some View {
        let angle = fraction * 360 - 90
        let radius = ringDiameter / 2
        let point = CGPoint(
            x: size / 2 + CGFloat(cos(angle * .pi / 180)) * radius,
            y: size / 2 + CGFloat(sin(angle * .pi / 180)) * radius
        )
        let markerSize = ringWidth * 0.95
        return Text(zone.emoji)
            .font(.system(size: ringWidth * 0.55))
            .frame(width: markerSize, height: markerSize)
            .background(.white.opacity(0.9), in: .circle)
            .overlay(Circle().stroke(zone.color(from: theme.zones).opacity(0.5), lineWidth: 1.5))
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            .opacity(0.85)
            .position(point)
            .transition(.scale.combined(with: .opacity))
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
            .overlay(Circle().stroke(currentZoneColor.opacity(0.4), lineWidth: 2))
            .shadow(color: currentZoneColor.opacity(0.3), radius: 4, x: 0, y: 2)
            .position(capPoint)
    }

    // MARK: - Center content

    private func centerContent(innerSize: CGFloat, containerSize: CGFloat, time: TimeInterval) -> some View {
        let phase = time * 0.3

        return ZStack {
            // Glass base
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: innerSize, height: innerSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

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
                    colors: [currentZoneColor.opacity(0.2), .clear],
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
                    .foregroundStyle(currentZoneColor)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .animation(.smooth(duration: 0.4), value: elapsedSeconds)
                    .shadow(color: currentZoneColor.opacity(0.3), radius: 8)

                StatusPill(title: statusLabel, tint: currentZoneColor)
            }
        }
    }

    // MARK: - Computed helpers

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

    private var currentZoneColor: Color {
        currentZone.color(from: theme.zones)
    }

    // MARK: - GaugeZone

    enum GaugeZone: CaseIterable, Identifiable {
        case postMeal, earlyFasting, fatBurning, deepFast

        var id: Self { self }

        var title: String {
            switch self {
            case .postMeal: "POST-MEAL"
            case .earlyFasting: "EARLY FAST"
            case .fatBurning: "FAT BURN"
            case .deepFast: "DEEP FAST"
            }
        }

        var emoji: String {
            switch self {
            case .postMeal: "🍽️"
            case .earlyFasting: "🌤️"
            case .fatBurning: "🔥"
            case .deepFast: "🌙"
            }
        }

        func color(from zones: ZoneColorSet) -> Color {
            switch self {
            case .postMeal: zones.postMeal
            case .earlyFasting: zones.earlyFasting
            case .fatBurning: zones.fatBurning
            case .deepFast: zones.deepFast
            }
        }

        /// Hours at which this zone ends; nil for the final open-ended zone.
        var endHours: Double? {
            switch self {
            case .postMeal: 4
            case .earlyFasting: 12
            case .fatBurning: 18
            case .deepFast: nil
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
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.18))
        )
        .overlay(
            Capsule(style: .continuous)
                .stroke(tint.opacity(0.45), lineWidth: 1)
        )
    }
}
