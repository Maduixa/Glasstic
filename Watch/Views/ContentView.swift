import SwiftUI
import WatchKit

struct ContentView: View {
    @EnvironmentObject private var fastingStore: WatchFastingStore
    @EnvironmentObject private var connectivity: WatchConnectivityService

    var body: some View {
        NavigationStack {
            if fastingStore.activeSession != nil {
                ActiveFastView()
            } else {
                IdleView()
            }
        }
    }
}

// MARK: - Active Fast View

struct ActiveFastView: View {
    @EnvironmentObject private var fastingStore: WatchFastingStore
    @EnvironmentObject private var connectivity: WatchConnectivityService

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Zone indicator
                ZoneBadgeView(zone: fastingStore.activeZone)
                    .padding(.top, 4)

                // Timer display
                VStack(spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    fastingStore.activeZone.watchColor,
                                    fastingStore.activeZone.watchColor.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("ELAPSED")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)

                // Progress ring
                CircularProgressView(
                    progress: fastingStore.currentProgress,
                    zone: fastingStore.activeZone
                )
                .frame(height: 80)
                .padding(.vertical, 4)

                // Time remaining (if not in deep ketosis)
                if fastingStore.activeZone != .deepKetosis {
                    Text("→ \(nextZoneName) in \(timeRemainingString)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Streak counter
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(fastingStore.streak)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("day streak")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)

                // End button
                Button {
                    endFast()
                } label: {
                    Text("End Fast")
                        .font(.system(size: 14, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red.opacity(0.8))
                .padding(.top, 8)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }

    private var timeString: String {
        let hours = fastingStore.elapsedHours
        let minutes = fastingStore.elapsedMinutes
        return String(format: "%d:%02d", hours, minutes)
    }

    private var timeRemainingString: String {
        let remaining = fastingStore.timeRemaining
        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private var nextZoneName: String {
        switch fastingStore.activeZone {
        case .postMeal:
            return "Early Fasting"
        case .earlyFasting:
            return "Fat Burning"
        case .fatBurning:
            return "Deep Fast"
        case .deepKetosis:
            return ""
        }
    }

    private func endFast() {
        connectivity.endFast()
        fastingStore.endFast()
    }
}

// MARK: - Idle View

struct IdleView: View {
    @EnvironmentObject private var fastingStore: WatchFastingStore
    @EnvironmentObject private var connectivity: WatchConnectivityService

    var body: some View {
        VStack(spacing: 16) {
            Spacer()

            // App icon placeholder
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.6, blue: 1.0),
                                Color(red: 0.3, green: 0.5, blue: 0.9)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    }

                Image(systemName: "timer")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white)
            }

            Text("Ready to Fast")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)

            // Streak (if any)
            if fastingStore.streak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    Text("\(fastingStore.streak)")
                        .font(.system(size: 14, weight: .semibold))
                    Text("day streak")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Start button
            Button {
                startFast()
            } label: {
                Text("Start Fast")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.4, green: 0.6, blue: 1.0))

            // Sync indicator
            if connectivity.isReachable {
                Label("iPhone connected", systemImage: "iphone.radiowaves.left.and.right")
                    .font(.system(size: 10))
                    .foregroundColor(.green)
            } else {
                Label("iPhone not connected", systemImage: "iphone.slash")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    private func startFast() {
        connectivity.startFast()
        fastingStore.startFast()
    }
}

// MARK: - Zone Badge View

struct ZoneBadgeView: View {
    let zone: FastingZone

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: zone.watchIcon)
                .font(.system(size: 12, weight: .semibold))
            Text(zone.shortName.uppercased())
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(zone.watchColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background {
            Capsule()
                .fill(zone.watchColor.opacity(0.2))
        }
    }
}

// MARK: - Circular Progress View

struct CircularProgressView: View {
    let progress: Double
    let zone: FastingZone

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: 8)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    zone.watchColor,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Percentage text
            VStack(spacing: 2) {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("of zone")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchFastingStore.shared)
        .environmentObject(WatchConnectivityService.shared)
}
