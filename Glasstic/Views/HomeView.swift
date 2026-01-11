import SwiftUI

struct HomeView: View {
    @Environment(FastingStore.self) private var store
    @State private var isSettingsPresented = false
    @State private var editingSession: SessionEditorContext?

    private var gradient: LinearGradient {
        let colors = store.selectedTheme.gradientColors
        return LinearGradient(
            colors: colors.isEmpty ? [.black, .gray] : colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

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
                gradient
                    .ignoresSafeArea()
                    .overlay(
                        RadialGradient(
                            colors: [
                                store.selectedTheme.accent.opacity(0.35),
                                Color.black.opacity(0.1)
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 600
                        )
                        .blendMode(.screen)
                        .opacity(0.6)
                    )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        timerCard
                        gaugeCard
                        aiInsightsCard
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
                .presentationBackground(.thinMaterial)
            }
        }
        .tint(store.selectedTheme.accent)
    }

    private var timerCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.activeSession == nil ? "Ready to fast" : "Time elapsed")
                        .font(.caption.smallCaps())
                        .foregroundStyle(.secondary)

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
                    .background(
                        store.selectedTheme.accent.opacity(0.12),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.98)))
                    .animation(.easeInOut(duration: 0.35), value: store.activeNudge)
            }

            Button(action: primaryAction) {
                Text(store.activeSession == nil ? "Start Fast" : "End Fast")
                    .font(.system(.headline, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(store.selectedTheme.accent.gradient)
                    )
                    .foregroundStyle(Color.black.opacity(0.8))
                    .shadow(color: store.selectedTheme.accent.opacity(0.6), radius: 16, x: 0, y: 12)
            }
            .buttonStyle(.plain)

            Text(completedText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .glassCard(material: store.selectedTheme.materialBias.material)
    }

    private var gaugeCard: some View {
        FastingGaugeView(
            elapsed: store.elapsed,
            thresholds: store.thresholds,
            activeZone: store.activeZone,
            accent: store.selectedTheme.accent
        )
        .glassCard(material: store.selectedTheme.materialBias.material)
    }

    private var aiInsightsCard: some View {
        AIInsightsView()
            .environment(store)
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
        .glassCard(material: store.selectedTheme.materialBias.material)
    }

    private var calendarCard: some View {
        CalendarPanelView(editingSession: $editingSession)
            .environment(store)
            .glassCard(material: store.selectedTheme.materialBias.material)
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
    var session: FastingSessionData
    var isNew: Bool
}
