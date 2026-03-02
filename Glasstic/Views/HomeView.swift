import CoreMotion
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: FastingStore
    @State private var isSettingsPresented = false
    @State private var editingSession: SessionEditorContext?

    private var elapsedText: String {
        guard let session = store.activeSession else {
            return "00:00"
        }
        return TimeFormatter.shared.shortElapsed(from: session.startDate, to: Date())
    }

    private var completedText: String {
        guard let session = store.sessions.first(where: { !$0.isActive }) else {
            return "No completed fasts yet"
        }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        let duration = formatter.string(from: session.duration) ?? "--"
        return "Last fast: \(duration)"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                FluidThemeBackground(
                    colors: store.selectedTheme.gradientColors,
                    accent: store.selectedTheme.accent
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        timerCard
                        gaugeCard
                        streakAndThemes
                        calendarCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
            }
            .navigationTitle("Liquid Glass")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isSettingsPresented.toggle()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(store.selectedTheme.accent)
                    }
                    .accessibilityLabel("Adjust fasting thresholds")
                }
            }
            .sheet(item: $editingSession) { context in
                SessionEditorView(
                    session: context.session,
                    thresholds: store.thresholds,
                    isNewEntry: context.isNew
                ) { updated in
                    store.updateSession(updated)
                } onDelete: { session in
                    store.delete(session)
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView(
                    thresholds: store.thresholds,
                    themes: AppTheme.allThemes,
                    selectedTheme: store.selectedTheme
                ) { newThresholds in
                    store.updateThresholds(newThresholds)
                } themeSelection: { theme in
                    store.updateTheme(to: theme)
                }
                .presentationDetents([.medium, .large])
                .presentationBackground(.clear)
            }
        }
        .tint(store.selectedTheme.accent)
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(store.activeSession == nil ? "Ready to fast" : "Time elapsed")
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)

                        if store.activeSession != nil {
                            Button {
                                if let session = store.activeSession {
                                    editingSession = SessionEditorContext(session: session, isNew: false)
                                }
                            } label: {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(store.selectedTheme.accent)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Edit fast start time")
                        }
                    }

                    Text(store.activeSession == nil ? "--:--" : elapsedText)
                        .font(.system(size: 48, weight: .semibold, design: .rounded))
                        .foregroundStyle(store.selectedTheme.accent)
                        .monospacedDigit()
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: store.elapsed)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Active zone")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(store.activeZone.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(store.selectedTheme.accent.opacity(0.18))
                                .overlay(
                                    Capsule()
                                        .stroke(store.selectedTheme.accent.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .animation(.easeInOut(duration: 0.25), value: store.activeZone)
                }
            }

            if store.activeNudge.isEmpty == false {
                Text(store.activeNudge)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(store.selectedTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .animation(.easeInOut(duration: 0.35), value: store.activeNudge)
            }

            Button(action: primaryAction) {
                HStack(spacing: 8) {
                    Image(systemName: store.activeSession == nil ? "play.fill" : "stop.fill")
                    Text(store.activeSession == nil ? "Start Fast" : "End Fast")
                }
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
            .buttonStyle(.glassProminent)
            .tint(store.selectedTheme.accent)

            Text(completedText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }

    private var gaugeCard: some View {
        FastingGaugeView(
            elapsed: store.elapsed,
            thresholds: store.thresholds,
            activeZone: store.activeZone,
            accent: store.selectedTheme.accent
        )
        .glassCard()
    }

    private var streakAndThemes: some View {
        VStack(spacing: 16) {
            HStack {
                Label {
                    Text("Streak")
                        .font(.headline)
                } icon: {
                    Text("🔥")
                        .font(.title3)
                }
                Spacer()
                Text("\(store.streakCount) day\(store.streakCount == 1 ? "" : "s")")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(store.selectedTheme.accent)
            }

            ThemePickerView(
                themes: AppTheme.allThemes,
                selected: store.selectedTheme
            ) { theme in
                withAnimation(.easeInOut(duration: 0.35)) {
                    store.updateTheme(to: theme)
                }
            }
        }
        .glassCard()
    }

    private var calendarCard: some View {
        CalendarPanelView(editingSession: $editingSession)
            .environmentObject(store)
            .glassCard()
    }

    private func primaryAction() {
        if store.activeSession == nil {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                store.startFast()
            }
        } else {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                store.endFast()
            }
        }
    }
}

private struct FluidThemeBackground: View {
    let colors: [Color]
    let accent: Color
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var motion = MotionProvider()

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            let baseColors = colors.isEmpty ? [Color.black, Color.gray] : colors
            let slow = t * 0.08
            let mid = t * 0.12
            let fast = t * 0.18
            let drift: CGFloat = 0.16
            let driftSmall: CGFloat = 0.1
            let parallax = motion.normalizedTilt
            let parallaxX = CGFloat(parallax.width) * 0.12
            let parallaxY = CGFloat(parallax.height) * 0.12
            let x1 = CGFloat(0.2 + drift * sin(slow) + parallaxX)
            let y1 = CGFloat(0.2 + drift * cos(slow * 0.9) + parallaxY)
            let x2 = CGFloat(0.8 + drift * cos(mid) - parallaxX * 0.9)
            let y2 = CGFloat(0.72 + drift * sin(mid * 1.1) - parallaxY * 0.9)
            let x3 = CGFloat(0.52 + driftSmall * sin(fast + 1.2) + parallaxX * 0.5)
            let y3 = CGFloat(0.12 + driftSmall * cos(fast * 0.8 + 0.5) + parallaxY * 0.5)
            let startX = CGFloat(0.1 + driftSmall * sin(slow * 0.7) + parallaxX * 0.5)
            let startY = CGFloat(0.04 + driftSmall * cos(slow * 0.6) + parallaxY * 0.5)
            let endX = CGFloat(0.9 + driftSmall * cos(slow * 0.8) - parallaxX * 0.5)
            let endY = CGFloat(0.96 + driftSmall * sin(slow * 0.9) - parallaxY * 0.5)

            ZStack {
                LinearGradient(
                    colors: baseColors,
                    startPoint: UnitPoint(x: clampedUnit(startX), y: clampedUnit(startY)),
                    endPoint: UnitPoint(x: clampedUnit(endX), y: clampedUnit(endY))
                )

                RadialGradient(
                    colors: [accent.opacity(0.5), .clear],
                    center: UnitPoint(x: clampedUnit(x1), y: clampedUnit(y1)),
                    startRadius: 20,
                    endRadius: 380
                )
                .blendMode(.screen)
                .blur(radius: 6)

                RadialGradient(
                    colors: [accent.opacity(0.3), .clear],
                    center: UnitPoint(x: clampedUnit(x2), y: clampedUnit(y2)),
                    startRadius: 28,
                    endRadius: 460
                )
                .blendMode(.screen)
                .blur(radius: 14)

                RadialGradient(
                    colors: [Color.white.opacity(0.14), .clear],
                    center: UnitPoint(x: clampedUnit(x3), y: clampedUnit(y3)),
                    startRadius: 18,
                    endRadius: 260
                )
                .blendMode(.screen)
                .opacity(0.55)
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

private extension Color {
    var gradient: LinearGradient {
        LinearGradient(
            colors: [self, self.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct SessionEditorContext: Identifiable {
    var id: UUID { session.id }
    var session: FastingSession
    var isNew: Bool
}
