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
    let height: CGFloat
    @State private var tabFrames: [BottomTab: CGRect] = [:]
    @State private var dragLocation: CGPoint?
    @State private var hoverTab: BottomTab?
    @State private var isDragging = false
    @StateObject private var motion = MotionProvider()
    @Namespace private var selectionNamespace

    var body: some View {
        let pillShape = Capsule()
        let bubblePadding = EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9)

        GlassEffectContainer(spacing: 24) {
            ZStack {
                GlassPillSurface(
                    shape: pillShape,
                    glassStyle: .clear,
                    tint: Color.black.opacity(0.02),
                    strokeWidth: 0.55,
                    highlightOpacity: 0.2,
                    showHighlight: false,
                    innerGlowOpacity: 0,
                    isInteractive: false,
                    shift: glassShift
                )

                HStack(spacing: 4) {
                    ForEach(BottomTab.allCases) { tab in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                                selectedTab = tab
                            }
                        } label: {
                            let scale = magnification(for: tab)
                            let lift = liftOffset(for: tab)
                            let isActive = activeTab == tab
                            VStack(spacing: 5) {
                                Image(systemName: tab.iconName)
                                    .font(.system(size: 19, weight: .semibold))
                                Text(tab.title)
                                    .font(.system(size: 12.5, weight: .semibold))
                            }
                            .foregroundStyle(isActive ? accentColor : .white.opacity(0.92))
                            .shadow(color: isActive ? accentColor.opacity(0.12) : .clear, radius: 6, x: 0, y: 0)
                            .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 0.5)
                            .padding(bubblePadding)
                            .background(alignment: .center) {
                                if isActive {
                                    GlassPillSurface(
                                        shape: pillShape,
                                        glassStyle: .regular,
                                        tint: Color.black.opacity(0.12),
                                        strokeWidth: 0.7,
                                        highlightOpacity: 0.48,
                                        showHighlight: true,
                                        innerGlowOpacity: 0.28,
                                        isInteractive: true,
                                        shift: glassShift
                                    )
                                    .matchedGeometryEffect(id: "pillSelection", in: selectionNamespace)
                                }
                            }
                            .scaleEffect(scale)
                            .offset(y: lift)
                            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: scale)
                            .frame(maxWidth: .infinity)
                            .background(
                                GeometryReader { proxy in
                                    Color.clear.preference(
                                        key: TabFramePreferenceKey.self,
                                        value: [tab: proxy.frame(in: .named("pill"))]
                                    )
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
            }
        }
        .compositingGroup()
        .clipShape(pillShape)
        .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
        .frame(height: height)
        .coordinateSpace(name: "pill")
        .contentShape(Capsule())
        .simultaneousGesture(dragGesture())
        .onPreferenceChange(TabFramePreferenceKey.self) { frames in
            tabFrames = frames
        }
        .onAppear { motion.start() }
        .onDisappear { motion.stop() }
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
    }

    private var activeTab: BottomTab {
        if isDragging, let hoverTab {
            return hoverTab
        }
        return selectedTab
    }

    private func dragGesture() -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("pill"))
            .onChanged { value in
                if !isDragging {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.78)) {
                        isDragging = true
                    }
                }
                let nearest = nearestTab(to: value.location)
                let width = selectionWidth(for: nearest ?? activeTab)
                dragLocation = clampedLocation(value.location, selectionWidth: width)
                hoverTab = nearest
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
        1.0
    }

    private func liftOffset(for tab: BottomTab) -> CGFloat {
        0
    }

    private func nearestTab(to location: CGPoint) -> BottomTab? {
        guard !tabFrames.isEmpty else { return nil }
        return tabFrames.min { lhs, rhs in
            abs(lhs.value.midX - location.x) < abs(rhs.value.midX - location.x)
        }?.key
    }

    private var interactionCenterX: CGFloat? {
        if let dragLocation {
            return dragLocation.x
        }
        return tabFrames[activeTab]?.midX
    }

    private func selectionWidth(for tab: BottomTab) -> CGFloat {
        guard let frame = tabFrames[tab] else {
            return max(60, height * 0.9)
        }
        return max(frame.width, height * 1.2)
    }

    private func clampedLocation(_ location: CGPoint, selectionWidth: CGFloat) -> CGPoint {
        guard !tabFrames.isEmpty else {
            return CGPoint(x: location.x, y: height / 2)
        }
        let halfWidth = selectionWidth / 2
        let minX = tabFrames.values.map(\.minX).min() ?? location.x
        let maxX = tabFrames.values.map(\.maxX).max() ?? location.x
        let clampedX = min(max(location.x, minX + halfWidth), maxX - halfWidth)
        return CGPoint(x: clampedX, y: height / 2)
    }

    private var glassShift: CGSize {
        let tilt = motion.normalizedTilt
        let tiltShift = CGSize(width: tilt.width * 0.1, height: tilt.height * 0.1)
        guard let bounds = pillBounds, let dragLocation else {
            return tiltShift
        }
        let normalizedX = (dragLocation.x - bounds.midX) / max(bounds.width, 1)
        let normalizedY = (dragLocation.y - bounds.midY) / max(bounds.height, 1)
        let dragShift = CGSize(width: normalizedX * 0.22, height: normalizedY * 0.22)
        return CGSize(width: tiltShift.width + dragShift.width, height: tiltShift.height + dragShift.height)
    }

    private var pillBounds: CGRect? {
        guard !tabFrames.isEmpty else { return nil }
        let minX = tabFrames.values.map(\.minX).min() ?? 0
        let maxX = tabFrames.values.map(\.maxX).max() ?? 0
        let minY = tabFrames.values.map(\.minY).min() ?? 0
        let maxY = tabFrames.values.map(\.maxY).max() ?? 0
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

private struct TabFramePreferenceKey: PreferenceKey {
    static let defaultValue: [BottomTab: CGRect] = [:]

    static func reduce(value: inout [BottomTab: CGRect], nextValue: () -> [BottomTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct GlassPillSurface<S: Shape>: View {
    let shape: S
    let glassStyle: Glass
    let tint: Color
    let strokeWidth: CGFloat
    let highlightOpacity: Double
    let showHighlight: Bool
    let innerGlowOpacity: Double
    let isInteractive: Bool
    let shift: CGSize

    var body: some View {
        let glass = isInteractive
        ? glassStyle.tint(tint).interactive()
        : glassStyle.tint(tint)

        shape
            .fill(.clear)
            .glassEffect(glass, in: shape)
            .clipShape(shape)
            .overlay(aberrationOverlay)
            .overlay(causticsOverlay)
            .overlay(highlightOverlay)
            .overlay(innerGlowOverlay)
    }

    private var aberrationOverlay: some View {
        ZStack {
            shape
                .stroke(Color.cyan.opacity(0.4), lineWidth: strokeWidth)
                .offset(x: -1.4)
                .blur(radius: 0.3)
                .blendMode(.screen)

            shape
                .stroke(Color.pink.opacity(0.4), lineWidth: strokeWidth)
                .offset(x: 1.4)
                .blur(radius: 0.3)
                .blendMode(.screen)
        }
    }

    private var causticsOverlay: some View {
        ZStack {
            RadialGradient(
                colors: [Color.white.opacity(0.32), .clear],
                center: UnitPoint(
                    x: clampedUnit(0.18 + shift.width),
                    y: clampedUnit(0.14 + shift.height)
                ),
                startRadius: 0,
                endRadius: 160
            )

            RadialGradient(
                colors: [Color.cyan.opacity(0.3), .clear],
                center: UnitPoint(
                    x: clampedUnit(0.82 - shift.width * 0.8),
                    y: clampedUnit(0.86 - shift.height * 0.6)
                ),
                startRadius: 0,
                endRadius: 180
            )

            RadialGradient(
                colors: [Color.blue.opacity(0.22), .clear],
                center: UnitPoint(
                    x: clampedUnit(0.35 + shift.width * 0.4),
                    y: clampedUnit(0.85 - shift.height * 0.3)
                ),
                startRadius: 0,
                endRadius: 200
            )
        }
        .blendMode(.screen)
        .blur(radius: 0.4)
        .clipShape(shape)
    }

    @ViewBuilder
    private var highlightOverlay: some View {
        if showHighlight {
            shape
                .stroke(
                    LinearGradient(
                        colors: [
                            .white.opacity(highlightOpacity),
                            .white.opacity(highlightOpacity * 0.4),
                            .clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: strokeWidth
                )
                .blendMode(.screen)
        }
    }

    @ViewBuilder
    private var innerGlowOverlay: some View {
        if innerGlowOpacity > 0 {
            shape
                .stroke(.white.opacity(innerGlowOpacity), lineWidth: strokeWidth)
                .blur(radius: 6)
                .blendMode(.screen)
        }
    }

    private func clampedUnit(_ value: CGFloat) -> CGFloat {
        min(max(value, 0.0), 1.0)
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
