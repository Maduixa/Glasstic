import CoreMotion
import SwiftUI

public struct ContentView: View {
    @Environment(FastingStore.self) private var store
    @State private var selectedTab: BottomTab = .session

    public init() {}

    private let bottomMenuHeight: CGFloat = 68

    public var body: some View {
        ZStack {
            LiquidBackground()

            VStack(spacing: 18) {
                tabContent
            }
            .padding(.horizontal, 20)
            .padding(.top, 32)
            .padding(.bottom, 50)
        }
        .safeAreaInset(edge: .bottom) {
            BottomPillMenu(
                selectedTab: $selectedTab,
                accentColor: accentColor,
                height: bottomMenuHeight
            )
        }
    }

    private var accentColor: Color { .cyan }
    private var actionColor: Color {
        store.isActive
        ? Color(red: 0.93, green: 0.32, blue: 0.32)
        : accentColor
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .session:
            sessionTab
        case .settings:
            settingsTab
        case .insights:
            PlaceholderTab(title: "Insights")
        case .rhythm:
            PlaceholderTab(title: "Rhythm")
        }
    }

    private var sessionTab: some View {
        VStack(spacing: 18) {
            GlassmorphicGauge(
                progress: store.progress,
                elapsed: store.elapsed,
                remaining: max(store.targetDuration - store.elapsed, 0),
                goal: store.targetDuration,
                isActive: store.isActive,
                accentColor: accentColor
            )

            actionButton

            Spacer(minLength: 0)
        }
    }

    private var settingsTab: some View {
        VStack(spacing: 18) {
            SettingsPanel(accentColor: accentColor)
            Spacer(minLength: 0)
        }
    }

    private var actionButton: some View {
        Button(action: {
            withAnimation(.bouncy) {
                if store.isActive {
                    store.endFast()
                } else {
                    store.startFast()
                }
            }
        }) {
            HStack(spacing: 10) {
                Image(systemName: store.isActive ? "stop.circle.fill" : "play.circle.fill")
                Text(store.isActive ? "End Fast" : "Start Fast")
            }
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .padding(.horizontal, 22)
            .frame(minWidth: 190)
        }
        .buttonStyle(.glassProminent)
        .tint(actionColor)
        .padding(.top, 8)
    }
}

// MARK: - Settings Panel

private struct SettingsPanel: View {
    @Environment(FastingStore.self) private var store
    let accentColor: Color

    private var goalHours: Binding<Double> {
        Binding(
            get: { store.targetDuration / 3600 },
            set: { store.updateTargetDuration(hours: $0) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Goal duration")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text("\(Int(goalHours.wrappedValue))h")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .animation(.smooth(duration: 0.25), value: goalHours.wrappedValue)
                }

                Slider(value: goalHours, in: 8...24, step: 1)
                    .tint(accentColor)

                Text("Used for progress and remaining time.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .padding(16)
            .glassEffect(.regular, in: .rect(cornerRadius: 22))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Placeholder Tab

private struct PlaceholderTab: View {
    let title: String

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
            Text("Coming soon")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bottom Tab

private enum BottomTab: String, CaseIterable, Identifiable {
    case session
    case insights
    case rhythm
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .session: return "Session"
        case .insights: return "Insights"
        case .rhythm: return "Rhythm"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .session: return "flame.fill"
        case .insights: return "chart.bar.fill"
        case .rhythm: return "moon.stars.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Bottom Pill Menu

private struct BottomPillMenu: View {
    @Binding var selectedTab: BottomTab
    let accentColor: Color
    let height: CGFloat
    @Namespace private var tabAnimation
    @State private var hoverTab: BottomTab?
    @State private var dragLocation: CGPoint?
    @State private var isDragging = false
    @State private var tabFrames: [BottomTab: CGRect] = [:]

    var body: some View {
        let pillShape = Capsule()
        let selectionTint = Color(hue: 0.52, saturation: 0.35, brightness: 0.95)

        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate

            GlassEffectContainer(spacing: 12) {
                ZStack {
                    // Main pill background with clear glass (less frosting)
                    pillShape
                        .fill(.clear)
                        .glassEffect(.clear, in: pillShape)
                        .allowsHitTesting(false)

                    // Tab buttons inside - on top of glass background
                    HStack(spacing: 0) {
                        ForEach(BottomTab.allCases) { tab in
                            let isSelected = selectedTab == tab
                            let isHovered = hoverTab == tab
                            let magnifyScale: CGFloat = isSelected ? 1.15 : (isHovered ? 1.08 : 1.0)

                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                                    selectedTab = tab
                                }
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: tab.iconName)
                                        .font(.system(size: 19, weight: .semibold))
                                        .symbolEffect(.bounce, value: isSelected)
                                    Text(tab.title)
                                        .font(.system(size: 12.5, weight: .semibold))
                                }
                                .foregroundStyle(isSelected ? .white : .white.opacity(0.65))
                                .shadow(color: isSelected ? selectionTint.opacity(0.6) : .clear, radius: 10)
                                .padding(.vertical, 10)
                                .padding(.horizontal, 8)
                                .frame(maxWidth: .infinity)
                                .scaleEffect(magnifyScale)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: magnifyScale)
                                .background {
                                    if isSelected {
                                        Capsule()
                                            .fill(.clear)
                                            .glassEffect(.regular.tint(selectionTint).interactive(), in: .capsule)
                                            .glassEffectID("selectedTab", in: tabAnimation)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .zIndex(isSelected ? 1 : 0)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: TabFrameKey.self,
                                        value: [tab: proxy.frame(in: .named("pill"))]
                                    )
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)

                    // Prismatic edge effects - on top but non-interactive
                    PrismaticEdge(intensity: isDragging ? 1.0 : 0.6, time: time)
                        .clipShape(pillShape)
                        .allowsHitTesting(false)

                    // Refraction caustics overlay
                    RefractionLayer(time: time, intensity: isDragging ? 0.5 : 0.3)
                        .clipShape(pillShape)
                        .allowsHitTesting(false)

                    // Prismatic rim highlight
                    pillShape
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .white.opacity(0.5),
                                    Color(hue: 0.0, saturation: 0.4, brightness: 1.0).opacity(0.3),
                                    .clear,
                                    Color(hue: 0.15, saturation: 0.5, brightness: 1.0).opacity(0.25),
                                    .clear,
                                    Color(hue: 0.55, saturation: 0.4, brightness: 1.0).opacity(0.3),
                                    .white.opacity(0.4)
                                ],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .blur(radius: 0.3)
                        .allowsHitTesting(false)
                }
                .frame(height: height)
                .coordinateSpace(name: "pill")
                .contentShape(pillShape)
                .simultaneousGesture(dragGesture)
                .onPreferenceChange(TabFrameKey.self) { tabFrames = $0 }
            }
            .shadow(color: .black.opacity(0.2), radius: 24, x: 0, y: 12)
            .shadow(color: selectionTint.opacity(0.12), radius: 20, x: 0, y: 6)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("pill"))
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        isDragging = true
                    }
                }
                dragLocation = value.location
                if let nearest = nearestTab(to: value.location), hoverTab != nearest {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                        hoverTab = nearest
                    }
                }
            }
            .onEnded { _ in
                if let hoverTab {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        selectedTab = hoverTab
                    }
                }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                    isDragging = false
                }
                dragLocation = nil
                hoverTab = nil
            }
    }

    private func nearestTab(to location: CGPoint) -> BottomTab? {
        tabFrames.min { abs($0.value.midX - location.x) < abs($1.value.midX - location.x) }?.key
    }
}

private struct TabFrameKey: PreferenceKey {
    static let defaultValue: [BottomTab: CGRect] = [:]
    static func reduce(value: inout [BottomTab: CGRect], nextValue: () -> [BottomTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Prismatic Edge Refraction

private struct PrismaticEdge: View {
    let intensity: CGFloat
    let time: TimeInterval

    var body: some View {
        let phase = time * 0.3

        ZStack {
            // Red channel - outer left edge
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.red.opacity(0.4 * intensity),
                            Color.red.opacity(0.15 * intensity),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.5
                )
                .offset(x: -2.0 * intensity + sin(phase) * 0.3)
                .blur(radius: 1.0)
                .blendMode(.plusLighter)

            // Orange/yellow - inner left
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.3 * intensity),
                            .clear,
                            Color.yellow.opacity(0.2 * intensity)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )
                .offset(x: -1.0 * intensity, y: 0.5 * intensity)
                .blur(radius: 0.6)
                .blendMode(.plusLighter)

            // Cyan channel - outer right edge
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.cyan.opacity(0.15 * intensity),
                            Color.cyan.opacity(0.45 * intensity)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    lineWidth: 2.5
                )
                .offset(x: 2.0 * intensity - sin(phase) * 0.3)
                .blur(radius: 1.0)
                .blendMode(.plusLighter)

            // Blue/violet - inner right
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.purple.opacity(0.2 * intensity),
                            .clear,
                            Color.blue.opacity(0.3 * intensity)
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    lineWidth: 1.8
                )
                .offset(x: 1.2 * intensity, y: -0.5 * intensity)
                .blur(radius: 0.6)
                .blendMode(.plusLighter)

            // Top specular rainbow band
            Capsule()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.red.opacity(0.25 * intensity),
                            Color.orange.opacity(0.2 * intensity),
                            Color.yellow.opacity(0.2 * intensity),
                            Color.green.opacity(0.15 * intensity),
                            Color.cyan.opacity(0.2 * intensity),
                            Color.blue.opacity(0.2 * intensity),
                            Color.purple.opacity(0.2 * intensity),
                            Color.red.opacity(0.25 * intensity)
                        ],
                        center: UnitPoint(x: 0.5 + sin(phase * 0.5) * 0.1, y: 0.3)
                    ),
                    lineWidth: 1.2
                )
                .blur(radius: 0.4)
                .blendMode(.plusLighter)
        }
    }
}

// MARK: - Refraction Layer

private struct RefractionLayer: View {
    let time: TimeInterval
    let intensity: CGFloat

    var body: some View {
        let phase = time * 0.4

        ZStack {
            // Moving caustic highlights
            RadialGradient(
                colors: [Color.white.opacity(0.35 * intensity), .clear],
                center: UnitPoint(
                    x: 0.2 + sin(phase * 0.6) * 0.1,
                    y: 0.3 + cos(phase * 0.5) * 0.15
                ),
                startRadius: 0,
                endRadius: 80
            )
            .blendMode(.plusLighter)

            RadialGradient(
                colors: [Color.cyan.opacity(0.25 * intensity), .clear],
                center: UnitPoint(
                    x: 0.8 - sin(phase * 0.5) * 0.08,
                    y: 0.6 + cos(phase * 0.4) * 0.1
                ),
                startRadius: 0,
                endRadius: 100
            )
            .blendMode(.plusLighter)

            // Specular highlight
            EllipticalGradient(
                colors: [Color.white.opacity(0.4 * intensity), .clear],
                center: UnitPoint(
                    x: 0.25 + sin(phase * 0.3) * 0.05,
                    y: 0.2 + cos(phase * 0.25) * 0.05
                ),
                startRadiusFraction: 0,
                endRadiusFraction: 0.4
            )
            .blendMode(.plusLighter)
            .blur(radius: 2)
        }
    }
}

// MARK: - Status Pill

private struct StatusPill: View {
    let isActive: Bool

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isActive ? Color.green : Color.orange)
                .frame(width: 6, height: 6)

            Text(isActive ? "Active" : "Ready")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .glassEffect(
            .regular.tint(isActive ? .green : .orange),
            in: .capsule
        )
    }
}

// MARK: - Liquid Background

private struct LiquidBackground: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var motion = MotionProvider()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let slow = t * 0.1
            let mid = t * 0.14
            let parallax = motion.normalizedTilt
            let parallaxX = CGFloat(parallax.width) * 0.12
            let parallaxY = CGFloat(parallax.height) * 0.12
            let drift: CGFloat = 0.14
            let driftSmall: CGFloat = 0.08

            let x1 = CGFloat(0.84 + drift * sin(slow) + parallaxX)
            let y1 = CGFloat(0.14 + drift * cos(slow * 1.1) + parallaxY)
            let x2 = CGFloat(0.16 + drift * cos(mid) - parallaxX * 0.9)
            let y2 = CGFloat(0.76 + drift * sin(mid * 1.05) - parallaxY * 0.9)
            let startX = CGFloat(0.08 + driftSmall * sin(slow * 0.8) + parallaxX * 0.5)
            let startY = CGFloat(0.02 + driftSmall * cos(slow * 0.7) + parallaxY * 0.5)
            let endX = CGFloat(0.92 + driftSmall * cos(slow * 0.9) - parallaxX * 0.5)
            let endY = CGFloat(0.98 + driftSmall * sin(slow) - parallaxY * 0.5)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.09, blue: 0.14),
                        Color(red: 0.04, green: 0.1, blue: 0.16),
                        Color(red: 0.02, green: 0.06, blue: 0.1)
                    ],
                    startPoint: UnitPoint(x: clampedUnit(startX), y: clampedUnit(startY)),
                    endPoint: UnitPoint(x: clampedUnit(endX), y: clampedUnit(endY))
                )

                RadialGradient(
                    colors: [Color.cyan.opacity(0.36), .clear],
                    center: UnitPoint(x: clampedUnit(x1), y: clampedUnit(y1)),
                    startRadius: 36,
                    endRadius: 320
                )

                RadialGradient(
                    colors: [Color.cyan.opacity(0.24), .clear],
                    center: UnitPoint(x: clampedUnit(x2), y: clampedUnit(y2)),
                    startRadius: 48,
                    endRadius: 300
                )
            }
            .ignoresSafeArea()
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                motion.start()
            case .inactive, .background:
                motion.stop()
            @unknown default:
                motion.stop()
            }
        }
    }

    private func clampedUnit(_ value: CGFloat) -> CGFloat {
        min(max(value, 0.0), 1.0)
    }
}

// MARK: - Motion Provider

@MainActor
private final class MotionProvider: ObservableObject {
    @Published var normalizedTilt = CGSize.zero

    private let manager = CMMotionManager()
    private var currentTilt = CGSize.zero

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        if manager.isDeviceMotionActive { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let maxTilt = 0.35
            let targetX = clamp(motion.attitude.roll / maxTilt)
            let targetY = clamp(motion.attitude.pitch / maxTilt)
            let smoothing: CGFloat = 0.18
            let nextX = currentTilt.width + (targetX - currentTilt.width) * smoothing
            let nextY = currentTilt.height + (targetY - currentTilt.height) * smoothing
            let next = CGSize(width: nextX, height: nextY)
            currentTilt = next
            normalizedTilt = next
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        currentTilt = .zero
        normalizedTilt = .zero
    }

    private func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, -1.0), 1.0))
    }
}
