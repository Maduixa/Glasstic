import CoreMotion
import SwiftUI

public struct ContentView: View {
    @Environment(FastingStore.self) private var store
    @State private var selectedTab: BottomTab = .session
    @State private var showProtocolPicker = false

    public init() {}

    private let bottomMenuHeight: CGFloat = 68

    public var body: some View {
        ZStack {
            LiquidBackground(accentColor: store.accentColor)

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
                accentColor: store.accentColor,
                height: bottomMenuHeight
            )
            .frame(height: bottomMenuHeight)
        }
        .sheet(isPresented: $showProtocolPicker) {
            ProtocolPickerSheet()
        }
    }

    private var accentColor: Color { store.accentColor }

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
            insightsTab
        case .rhythm:
            rhythmTab
        }
    }

    // MARK: - Session Tab

    private var sessionTab: some View {
        ScrollView {
            VStack(spacing: 18) {
                GlassmorphicGauge(
                    progress: store.progress,
                    elapsed: store.elapsed,
                    remaining: store.remainingTime,
                    goal: store.targetDuration,
                    isActive: store.isActive,
                    currentZone: store.currentZone,
                    estimatedCalories: store.estimatedCalories
                )

                // Zone progress card when active
                if store.isActive {
                    ZoneProgressCard(
                        currentZone: store.currentZone,
                        zoneProgress: store.zoneProgress,
                        timeToNextZone: store.timeToNextZone
                    )
                }

                actionButton

                // Protocol selector when not active
                if !store.isActive {
                    protocolSelector
                }

                Spacer(minLength: 0)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Insights Tab

    private var insightsTab: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Insights")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Stats cards
                StatsCard()

                // Zones overview
                ZonesOverviewCard(
                    currentZone: store.currentZone,
                    elapsed: store.elapsed
                )

                Spacer(minLength: 0)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Rhythm Tab

    private var rhythmTab: some View {
        VStack(spacing: 18) {
            Text("Rhythm")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Calendar and history coming soon")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))

            Spacer(minLength: 0)
        }
    }

    // MARK: - Settings Tab

    private var settingsTab: some View {
        ScrollView {
            VStack(spacing: 18) {
                SettingsPanel(accentColor: accentColor)
                Spacer(minLength: 0)
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: - Components

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

    private var protocolSelector: some View {
        Button(action: { showProtocolPicker = true }) {
            HStack {
                Image(systemName: store.selectedProtocol.iconName)
                    .foregroundStyle(accentColor)
                Text(store.selectedProtocol.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(store.targetDuration / 3600))h goal")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .liquidGlass(
                        .regular
                            .tint(.white)
                            .cornerRadius(16),
                        in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stats Card

private struct StatsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)

            HStack(spacing: 16) {
                StatItem(value: "3", label: "Fasts", icon: "flame.fill")
                StatItem(value: "48h", label: "Total", icon: "clock.fill")
                StatItem(value: "16h", label: "Average", icon: "chart.bar.fill")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Protocol Picker Sheet

private struct ProtocolPickerSheet: View {
    @Environment(FastingStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(FastingProtocol.allCases) { fastingProtocol in
                    Button(action: {
                        store.selectProtocol(fastingProtocol)
                        dismiss()
                    }) {
                        HStack {
                            Image(systemName: fastingProtocol.iconName)
                                .foregroundStyle(.cyan)
                                .frame(width: 30)
                            VStack(alignment: .leading) {
                                Text(fastingProtocol.name)
                                    .font(.headline)
                                Text(fastingProtocol.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if store.selectedProtocol == fastingProtocol {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.cyan)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Fasting Protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
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
    
    private var notificationsBinding: Binding<Bool> {
        Binding(
            get: { store.notificationsEnabled },
            set: { newValue in
                if newValue && !store.notificationsAuthorized {
                    Task { await store.requestNotificationAuthorization() }
                } else {
                    store.notificationsEnabled = newValue
                }
            }
        )
    }
    
    private var healthKitBinding: Binding<Bool> {
        Binding(
            get: { store.healthKitEnabled },
            set: { newValue in
                if newValue && !store.healthKitAuthorized {
                    Task { await store.requestHealthKitAuthorization() }
                } else {
                    store.healthKitEnabled = newValue
                }
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Settings")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)

            // Goal duration
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

                Slider(value: goalHours, in: 1...72, step: 1)
                    .tint(accentColor)

                Text("Adjust your fasting goal duration.")
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

            // Current protocol info
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: store.selectedProtocol.iconName)
                        .foregroundStyle(accentColor)
                    Text("Current Protocol")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    Text(store.selectedProtocol.name)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                Text(store.selectedProtocol.description)
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
            
            // Notifications section
            SettingsSection(title: "Notifications", icon: "bell.fill", accentColor: accentColor) {
                SettingsToggleRow(
                    title: "Notifications",
                    subtitle: store.notificationsAuthorized ? "Enabled" : "Tap to enable",
                    icon: "bell.badge.fill",
                    isOn: notificationsBinding,
                    accentColor: accentColor
                )
                
                if store.notificationsEnabled {
                    SettingsInfoRow(
                        title: "Zone Alerts",
                        value: "On",
                        icon: "flame.fill"
                    )
                    SettingsInfoRow(
                        title: "Goal Reminders",
                        value: "On",
                        icon: "target"
                    )
                    SettingsInfoRow(
                        title: "Hydration Reminders",
                        value: "Every 2h",
                        icon: "drop.fill"
                    )
                }
            }
            
            // HealthKit section
            SettingsSection(title: "Health", icon: "heart.fill", accentColor: accentColor) {
                SettingsToggleRow(
                    title: "Apple Health",
                    subtitle: store.healthKitAuthorized ? "Connected" : "Tap to connect",
                    icon: "heart.text.square.fill",
                    isOn: healthKitBinding,
                    accentColor: accentColor
                )
                
                if store.healthKitEnabled, let profile = store.userProfile {
                    if let weight = profile.weightKg {
                        SettingsInfoRow(
                            title: "Weight",
                            value: String(format: "%.1f kg", weight),
                            icon: "scalemass.fill"
                        )
                    }
                    if let height = profile.heightCm {
                        SettingsInfoRow(
                            title: "Height",
                            value: String(format: "%.0f cm", height),
                            icon: "ruler.fill"
                        )
                    }
                    if let bmr = profile.calculatedBMR ?? profile.estimatedBMR {
                        SettingsInfoRow(
                            title: "Est. BMR",
                            value: String(format: "%.0f kcal", bmr),
                            icon: "flame.fill"
                        )
                    }
                }
            }
            
            // About section
            SettingsSection(title: "About", icon: "info.circle.fill", accentColor: accentColor) {
                SettingsInfoRow(
                    title: "Version",
                    value: "1.0.0",
                    icon: "app.badge.fill"
                )
                SettingsInfoRow(
                    title: "Build",
                    value: "1",
                    icon: "hammer.fill"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Settings Section

private struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                    .font(.subheadline)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            
            VStack(spacing: 0) {
                content
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

// MARK: - Settings Toggle Row

private struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isOn ? accentColor : .white.opacity(0.5))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Settings Info Row

private struct SettingsInfoRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 28)
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Bottom Tab Enum

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

// MARK: - Liquid Background

private struct LiquidBackground: View {
    let accentColor: Color
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

                // Primary accent glow
                RadialGradient(
                    colors: [accentColor.opacity(0.36), .clear],
                    center: UnitPoint(x: clampedUnit(x1), y: clampedUnit(y1)),
                    startRadius: 36,
                    endRadius: 320
                )
                .blendMode(.screen)
                .blur(radius: 12)

                // Secondary accent glow
                RadialGradient(
                    colors: [accentColor.opacity(0.24), .clear],
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

// MotionProvider is defined in Utilities/MotionProvider.swift

// MARK: - Bottom Pill Menu

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

    private func nearestTab(to location: CGPoint) -> BottomTab? {
        guard !tabFrames.isEmpty else { return nil }
        return tabFrames.min { lhs, rhs in
            abs(lhs.value.midX - location.x) < abs(rhs.value.midX - location.x)
        }?.key
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

// MARK: - Tab Frame Preference Key

private struct TabFramePreferenceKey: PreferenceKey {
    static let defaultValue: [BottomTab: CGRect] = [:]

    static func reduce(value: inout [BottomTab: CGRect], nextValue: () -> [BottomTab: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

// MARK: - Glass Pill Surface

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
