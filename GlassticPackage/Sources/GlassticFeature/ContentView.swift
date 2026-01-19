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
            BottomPillMenu(selectedTab: $selectedTab, accentColor: accentColor)
                .frame(height: bottomMenuHeight)
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
            .background(
                Capsule(style: .circular)
                    .fill(
                        LinearGradient(
                            colors: [
                                actionColor.opacity(0.9),
                                actionColor.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
        .shadow(color: actionColor.opacity(0.4), radius: 16, x: 0, y: 10)
        .padding(.top, 8)
    }

}

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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

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

private enum BottomTab: String, CaseIterable, Identifiable {
    case session
    case insights
    case rhythm
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .session:
            return "Session"
        case .insights:
            return "Insights"
        case .rhythm:
            return "Rhythm"
        case .settings:
            return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .session:
            return "flame.fill"
        case .insights:
            return "chart.bar.fill"
        case .rhythm:
            return "moon.stars.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
}

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
                .blendMode(.screen)
                .blur(radius: 12)

                RadialGradient(
                    colors: [Color.cyan.opacity(0.24), .clear],
                    center: UnitPoint(x: clampedUnit(x2), y: clampedUnit(y2)),
                    startRadius: 48,
                    endRadius: 300
                )
                .blendMode(.screen)
                .blur(radius: 14)
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

private struct BottomPillMenu: View {
    @Binding var selectedTab: BottomTab
    let accentColor: Color
    @State private var tabFrames: [BottomTab: CGRect] = [:]
    @State private var dragLocation: CGPoint?
    @State private var hoverTab: BottomTab?
    @State private var isDragging = false

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.2),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .blendMode(.overlay)
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 8)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

            if let lensCenter, let lensSize {
                MagnifyBubble(accentColor: accentColor, isDragging: isDragging)
                    .frame(width: lensSize.width, height: lensSize.height)
                    .position(lensCenter)
                    .scaleEffect(isDragging ? 1.08 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.82), value: lensCenter)
                    .animation(.spring(response: 0.3, dampingFraction: 0.76), value: isDragging)
            }

            HStack(spacing: 6) {
                ForEach(BottomTab.allCases) { tab in
                    Button {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    } label: {
                        let scale = magnification(for: tab)
                        let lift = liftOffset(for: tab)
                        VStack(spacing: 5) {
                            Image(systemName: tab.iconName)
                                .font(.system(size: 19, weight: .semibold))
                            Text(tab.title)
                                .font(.system(size: 12.5, weight: .semibold))
                        }
                        .foregroundStyle(activeTab == tab ? accentColor : .white.opacity(0.82))
                        .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 12)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: TabFramePreferenceKey.self,
                                    value: [tab: proxy.frame(in: .named("pill"))]
                                )
                            }
                        )
                        .scaleEffect(scale)
                        .offset(y: lift)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scale)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
        }
        .coordinateSpace(name: "pill")
        .contentShape(Capsule())
        .simultaneousGesture(dragGesture)
        .onPreferenceChange(TabFramePreferenceKey.self) { frames in
            tabFrames = frames
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var activeTab: BottomTab {
        if isDragging, let hoverTab {
            return hoverTab
        }
        return selectedTab
    }

    private var lensCenter: CGPoint? {
        if let dragLocation {
            return clampedLocation(dragLocation)
        }
        guard let frame = tabFrames[activeTab] else { return nil }
        return CGPoint(x: frame.midX, y: frame.midY + 2)
    }

    private var lensSize: CGSize? {
        guard let frame = tabFrames[activeTab] else { return nil }
        let height = max(frame.height * 0.95, 48)
        let width = max(frame.width * 0.95, 65)
        return CGSize(width: width, height: height)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("pill"))
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        isDragging = true
                    }
                }
                dragLocation = value.location
                hoverTab = nearestTab(to: value.location)
            }
            .onEnded { _ in
                if let hoverTab {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = hoverTab
                    }
                }
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    isDragging = false
                }
                dragLocation = nil
                hoverTab = nil
            }
    }

    private func magnification(for tab: BottomTab) -> CGFloat {
        guard let lensCenter, let frame = tabFrames[tab] else {
            return activeTab == tab ? 1.08 : 1.0
        }
        let distance = abs(frame.midX - lensCenter.x)
        let maxDistance = frame.width * 1.15
        let influence = max(0, 1 - distance / maxDistance)
        let boost = isDragging ? 0.22 : 0.12
        return 1 + influence * boost
    }

    private func liftOffset(for tab: BottomTab) -> CGFloat {
        guard let lensCenter, let frame = tabFrames[tab] else {
            return activeTab == tab ? -2 : 0
        }
        let distance = abs(frame.midX - lensCenter.x)
        let maxDistance = frame.width * 1.2
        let influence = max(0, 1 - distance / maxDistance)
        return -2 - (influence * (isDragging ? 6 : 3))
    }

    private func nearestTab(to location: CGPoint) -> BottomTab? {
        guard !tabFrames.isEmpty else { return nil }
        return tabFrames.min { lhs, rhs in
            abs(lhs.value.midX - location.x) < abs(rhs.value.midX - location.x)
        }?.key
    }

    private func clampedLocation(_ location: CGPoint) -> CGPoint {
        guard let lensSize else { return location }
        let halfWidth = lensSize.width / 2
        let minX = tabFrames.values.map(\.minX).min() ?? location.x
        let maxX = tabFrames.values.map(\.maxX).max() ?? location.x
        let clampedX = min(max(location.x, minX + halfWidth), maxX - halfWidth)
        let y = tabFrames[activeTab]?.midY ?? location.y
        return CGPoint(x: clampedX, y: y)
    }
}

private struct TabFramePreferenceKey: PreferenceKey {
    static let defaultValue: [BottomTab: CGRect] = [:]

    static func reduce(value: inout [BottomTab: CGRect], nextValue: () -> [BottomTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct MagnifyBubble: View {
    let accentColor: Color
    let isDragging: Bool

    var body: some View {
        ZStack {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isDragging ? 0.35 : 0.28),
                            Color.white.opacity(isDragging ? 0.22 : 0.18),
                            Color.white.opacity(isDragging ? 0.15 : 0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .white.opacity(isDragging ? 0.45 : 0.35),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
                .blendMode(.overlay)

            Capsule()
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(isDragging ? 0.25 : 0.18),
                            .clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .blendMode(.screen)

            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.6),
                            Color.white.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )

            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.black.opacity(0.06)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(3)
        }
        .shadow(color: accentColor.opacity(isDragging ? 0.45 : 0.3), radius: 16, x: 0, y: 8)
        .shadow(color: .white.opacity(0.2), radius: 8, x: 0, y: -2)
        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}

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
                .shadow(color: .black.opacity(0.35), radius: 2, x: 0, y: 1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .liquidGlass(
            .regular
                .tint(isActive ? .green : .orange)
                .cornerRadius(999),
            in: Capsule()
        )
    }
}
