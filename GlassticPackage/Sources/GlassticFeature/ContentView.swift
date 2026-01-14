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
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.09, blue: 0.14),
                    Color(red: 0.04, green: 0.1, blue: 0.16),
                    Color(red: 0.02, green: 0.06, blue: 0.1)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            RadialGradient(
                colors: [Color.cyan.opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 260
            )

            RadialGradient(
                colors: [Color.cyan.opacity(0.12), .clear],
                center: .bottomLeading,
                startRadius: 60,
                endRadius: 240
            )
        }
        .ignoresSafeArea()
    }
}

private struct BottomPillMenu: View {
    @Binding var selectedTab: BottomTab
    let accentColor: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(BottomTab.allCases) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.iconName)
                            .font(.system(size: 19, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 12.5, weight: .semibold))
                    }
                    .foregroundStyle(selectedTab == tab ? accentColor : .white.opacity(0.82))
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 0.5)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .padding(.horizontal, 12)
                    .background {
                        if selectedTab == tab {
                            Capsule(style: .circular)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    Capsule(style: .circular)
                                        .stroke(accentColor.opacity(0.28), lineWidth: 1.1)
                                )
                            .shadow(color: .white.opacity(0.12), radius: 4, x: 0, y: 0.5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.07),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay(
            Capsule()
                .stroke(.white.opacity(0.12), lineWidth: 0.9)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 6)
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
