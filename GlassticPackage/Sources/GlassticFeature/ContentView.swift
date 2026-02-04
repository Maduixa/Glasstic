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
        .buttonStyle(.plain)
        .refractiveGlass(
            tint: actionColor,
            interactive: true,
            in: .rect(cornerRadius: 22)
        )
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
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            }
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

// MARK: - Selection Background (removed - using glass effect directly)

// MARK: - Bottom Pill Menu

private struct BottomPillMenu: View {
    @Binding var selectedTab: BottomTab
    let accentColor: Color
    let height: CGFloat
    
    @State private var hoverTab: BottomTab?
    @State private var dragLocation: CGPoint?
    @State private var isDragging = false
    @State private var tabFrames: [BottomTab: CGRect] = [:]
    @State private var containerFrame: CGRect = .zero
    @State private var selectionOffset: CGFloat = 0
    @State private var targetSelectionOffset: CGFloat = 0
    @State private var selectionVelocity: CGFloat = 0
    @State private var wobblePhase: CGFloat = 0
    @State private var wobbleAmplitude: CGFloat = 0
    @State private var time: CGFloat = 0
    @State private var pressedTab: BottomTab?
    @State private var blobScales: [BottomTab: CGFloat] = [:]

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let _ = updateAnimation(timeline.date)
            
            GlassEffectContainer(spacing: 40) {
                ZStack {
                    selectionBlobLayer
                    
                    HStack(spacing: 0) {
                        ForEach(BottomTab.allCases) { tab in
                            tabButton(for: tab)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                }
                .frame(height: height)
                .background {
                    pillBackground
                }
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(
                            key: ContainerFrameKey.self,
                            value: proxy.frame(in: .named("pill"))
                        )
                    }
                )
            }
            .coordinateSpace(name: "pill")
            .contentShape(Capsule())
            .simultaneousGesture(dragGesture)
            .onPreferenceChange(TabFrameKey.self) { frames in
                tabFrames = frames
                updateSelectionTarget()
            }
            .onPreferenceChange(ContainerFrameKey.self) { frame in
                containerFrame = frame
                updateSelectionTarget()
            }
            .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
            .shadow(color: accentColor.opacity(0.2), radius: 40, x: 0, y: 8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    private func updateAnimation(_ date: Date) {
        let dt: CGFloat = 1.0 / 60.0
        time = CGFloat(date.timeIntervalSinceReferenceDate)
        
        wobblePhase += 8.0 * dt
        if wobblePhase > .pi * 2 { wobblePhase -= .pi * 2 }
        
        wobbleAmplitude *= 0.92
        if wobbleAmplitude < 0.001 { wobbleAmplitude = 0 }
        
        let displacement = selectionOffset - targetSelectionOffset
        let springForce = -220.0 * displacement
        let dampingForce = -0.7 * 220.0 * 2 * selectionVelocity
        let acceleration = springForce + dampingForce
        
        selectionVelocity += acceleration * dt
        selectionOffset += selectionVelocity * dt
        
        if abs(selectionVelocity) < 0.1 && abs(displacement) < 0.5 {
            selectionOffset = targetSelectionOffset
            selectionVelocity = 0
        }
    }
    
    private func updateSelectionTarget() {
        guard let frame = tabFrames[selectedTab] else { return }
        let newTarget = frame.midX
        if abs(targetSelectionOffset - newTarget) > 1 {
            wobbleAmplitude = min(wobbleAmplitude + 0.03, 0.06)
        }
        targetSelectionOffset = newTarget
    }
    
    @ViewBuilder
    private var selectionBlobLayer: some View {
        if let frame = tabFrames[selectedTab] {
            let stretchFactor = 1.0 + min(abs(selectionVelocity) * 0.0008, 0.15)
            let wobbleX = sin(wobblePhase) * wobbleAmplitude * 8
            let wobbleScaleX = 1.0 + cos(wobblePhase * 1.3) * wobbleAmplitude * 0.3
            let wobbleScaleY = 1.0 + sin(wobblePhase * 0.9) * wobbleAmplitude * 0.2
            
            Capsule(style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            accentColor.opacity(0.4),
                            accentColor.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: frame.width * 0.7
                    )
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    accentColor.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .frame(width: frame.width * stretchFactor * wobbleScaleX, height: frame.height * wobbleScaleY)
                .position(x: selectionOffset + wobbleX, y: containerFrame.midY)
                .blur(radius: 1)
                .blendMode(.plusLighter)
        }
    }
    
    private var pillBackground: some View {
        ZStack {
            AnimatedCausticBackdrop(time: time, accentColor: accentColor)
                .clipShape(Capsule(style: .continuous))
            
            Capsule(style: .continuous)
                .fill(Color.white.opacity(0.03))
                .clearLiquidGlass(
                    cornerRadius: 0.15,
                    refraction: 0.28,
                    chromaticSpread: 0.07,
                    edgeHighlight: 0.6,
                    causticIntensity: 0.4,
                    wobbleAmount: 0.015 + wobbleAmplitude * 0.6,
                    wobbleFreq: 5.0,
                    time: time,
                    maxSampleOffset: CGSize(width: 120, height: 120)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    Color.white.opacity(0.1),
                                    Color.white.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        }
    }
    
    @ViewBuilder
    private func tabButton(for tab: BottomTab) -> some View {
        let isSelected = selectedTab == tab
        let isHovered = hoverTab == tab
        let isPressed = pressedTab == tab
        let blobScale = blobScales[tab] ?? 1.0
        
        let baseScale: CGFloat = isSelected ? 1.1 : (isHovered ? 1.05 : 1.0)
        let pressScale: CGFloat = isPressed ? 0.92 : 1.0
        let finalScale = baseScale * pressScale * blobScale

        Button {
            withAnimation(.bouncy(duration: 0.4)) {
                selectedTab = tab
                wobbleAmplitude = 0.05
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .symbolEffect(.bounce, value: isSelected)
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(isSelected ? Color.white : .white.opacity(0.55))
            .shadow(color: isSelected ? accentColor : .clear, radius: 16, x: 0, y: 0)
            .shadow(color: isSelected ? accentColor.opacity(0.6) : .clear, radius: 6, x: 0, y: 0)
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .scaleEffect(finalScale)
            .animation(.bouncy(duration: 0.25), value: finalScale)
        }
        .frame(maxWidth: .infinity)
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
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if pressedTab != tab {
                        pressedTab = tab
                        withAnimation(.bouncy(duration: 0.15)) {
                            blobScales[tab] = 0.95
                        }
                    }
                }
                .onEnded { _ in
                    pressedTab = nil
                    withAnimation(.bouncy(duration: 0.4)) {
                        blobScales[tab] = 1.0
                    }
                    wobbleAmplitude = min(wobbleAmplitude + 0.02, 0.06)
                }
        )

        if isSelected {
            EmptyView()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("pill"))
            .onChanged { value in
                if !isDragging {
                    withAnimation(.bouncy(duration: 0.2)) {
                        isDragging = true
                    }
                    wobbleAmplitude = 0.03
                }
                dragLocation = value.location
                if let nearest = nearestTab(to: value.location), hoverTab != nearest {
                    withAnimation(.bouncy(duration: 0.3)) {
                        hoverTab = nearest
                    }
                }
            }
            .onEnded { _ in
                if let hoverTab {
                    withAnimation(.bouncy(duration: 0.4)) {
                        selectedTab = hoverTab
                    }
                    wobbleAmplitude = 0.05
                }
                withAnimation(.bouncy(duration: 0.3)) {
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

private struct ContainerFrameKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

private struct TabFrameKey: PreferenceKey {
    static let defaultValue: [BottomTab: CGRect] = [:]
    static func reduce(value: inout [BottomTab: CGRect], nextValue: () -> [BottomTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

private struct AnimatedCausticBackdrop: View {
    let time: CGFloat
    let accentColor: Color
    
    var body: some View {
        let slow = time * 0.08
        let mid = time * 0.12
        let fast = time * 0.18
        
        Canvas { context, size in
            let w = size.width
            let h = size.height
            
            let caustic1Center = CGPoint(
                x: w * (0.2 + 0.15 * sin(slow)),
                y: h * (0.3 + 0.2 * cos(slow * 1.1))
            )
            let caustic2Center = CGPoint(
                x: w * (0.75 + 0.12 * cos(mid)),
                y: h * (0.6 + 0.15 * sin(mid * 0.9))
            )
            let caustic3Center = CGPoint(
                x: w * (0.5 + 0.1 * sin(fast)),
                y: h * (0.5 + 0.1 * cos(fast * 1.2))
            )
            
            context.drawLayer { ctx in
                let gradient1 = Gradient(colors: [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.08),
                    Color.clear
                ])
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: caustic1Center.x - 80,
                        y: caustic1Center.y - 40,
                        width: 160,
                        height: 80
                    )),
                    with: .radialGradient(
                        gradient1,
                        center: caustic1Center,
                        startRadius: 0,
                        endRadius: 90
                    )
                )
            }
            
            context.drawLayer { ctx in
                let gradient2 = Gradient(colors: [
                    accentColor.opacity(0.3),
                    accentColor.opacity(0.1),
                    Color.clear
                ])
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: caustic2Center.x - 70,
                        y: caustic2Center.y - 35,
                        width: 140,
                        height: 70
                    )),
                    with: .radialGradient(
                        gradient2,
                        center: caustic2Center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
            }
            
            context.drawLayer { ctx in
                let gradient3 = Gradient(colors: [
                    Color.white.opacity(0.15),
                    Color.clear
                ])
                ctx.fill(
                    Path(ellipseIn: CGRect(
                        x: caustic3Center.x - 50,
                        y: caustic3Center.y - 25,
                        width: 100,
                        height: 50
                    )),
                    with: .radialGradient(
                        gradient3,
                        center: caustic3Center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
            }
            
            for i in 0..<5 {
                let phase = time * 0.15 + Double(i) * 0.7
                let sparkleX = w * (0.1 + 0.8 * (Double(i) / 5.0) + 0.05 * sin(phase))
                let sparkleY = h * (0.3 + 0.4 * cos(phase * 0.8 + Double(i)))
                let sparkleAlpha = 0.3 + 0.4 * (0.5 + 0.5 * sin(phase * 2))
                
                context.drawLayer { ctx in
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: sparkleX - 3, y: sparkleY - 3, width: 6, height: 6)),
                        with: .color(Color.white.opacity(sparkleAlpha))
                    )
                }
            }
        }
        .blendMode(.plusLighter)
    }
}

// Subtle moving caustics so refraction reads against a flat background.
private struct CausticPillBackdrop: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let slow = t * 0.12
            let mid = t * 0.18

            ZStack {
                RadialGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.2 + 0.12 * sin(slow), y: 0.3 + 0.1 * cos(slow)),
                    startRadius: 0,
                    endRadius: 140
                )
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.2),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.8 + 0.1 * cos(mid), y: 0.7 + 0.08 * sin(mid)),
                    startRadius: 0,
                    endRadius: 120
                )
            }
            .blendMode(.plusLighter)
            .opacity(0.5)
        }
    }
}

// MARK: - Transparent Glass Pill (removed - replaced by refractive tab glass)



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
#Preview("ContentView") {
    ContentView()
        .environment(FastingStore())
}
