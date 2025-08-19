import SwiftUI
import ActivityKit
import Combine
import UIKit

// MARK: - Fasting Manager
class FastingManager: ObservableObject {
    // Using a shared UserDefaults suite for App Group data sharing
    private let sharedDefaults: UserDefaults

    @Published var fastingState: FastingState = .idle {
        didSet { 
            sharedDefaults.set(fastingState.rawValue, forKey: "fastingState")
            sendContextToWatch()
        }
    }
    @Published var elapsedTime: TimeInterval = 0 {
        didSet { sendContextToWatch() }
    }
    
    private var fastingStartDate: Double = 0 {
        didSet { sharedDefaults.set(fastingStartDate, forKey: "fastingStartDate") }
    }
    private var fastingGoal: TimeInterval = 0 {
        didSet { sharedDefaults.set(fastingGoal, forKey: "fastingGoal") }
    }

    private var timer: Timer?
    private let connectivityManager = WatchConnectivityManager.shared
    private var currentActivity: Activity<FastingActivityAttributes>?

    init() {
        guard let defaults = UserDefaults(suiteName: "group.com.yourcompany.Glasstic") else {
            fatalError("Could not initialize shared UserDefaults. Please check your App Group configuration.")
        }
        self.sharedDefaults = defaults

        self.fastingState = FastingState(rawValue: sharedDefaults.string(forKey: "fastingState") ?? "idle") ?? .idle
        self.fastingStartDate = sharedDefaults.double(forKey: "fastingStartDate")
        self.fastingGoal = sharedDefaults.double(forKey: "fastingGoal")

        if fastingState == .fasting {
            let startDate = Date(timeIntervalSince1970: fastingStartDate)
            self.elapsedTime = Date().timeIntervalSince(startDate)
            startTimer()
        }
        
        NotificationManager.shared.requestAuthorization()
        HealthKitManager.shared.requestAuthorization { _, _ in }
        sendContextToWatch() // Initial sync
    }

    func startFasting(goal: TimeInterval) {
        let startDate = Date()
        fastingStartDate = startDate.timeIntervalSince1970
        fastingState = .fasting
        fastingGoal = goal
        elapsedTime = 0
        startTimer()
        
        // Schedule AI-generated notification
        NotificationManager.shared.scheduleAINotification(for: goal)

        // Start Live Activity
        let attributes = FastingActivityAttributes(fastingGoal: goal)
        let initialState = FastingActivityAttributes.ContentState(elapsedTime: 0, currentZoneName: "Anabolic", progress: 0)
        
        do {
            currentActivity = try Activity<FastingActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            print("Live Activity started.")
        } catch (let error) {
            print("Error starting Live Activity: \(error.localizedDescription)")
        }
    }

    func endFasting() {
        if fastingStartDate > 0 {
            let startDate = Date(timeIntervalSince1970: fastingStartDate)
            let endDate = Date()
            HealthKitManager.shared.saveFast(startDate: startDate, endDate: endDate) { _, _ in }
            GamificationManager.shared.processCompletedFast(startDate: startDate, endDate: endDate)
        }
        
        fastingState = .idle
        timer?.invalidate()
        timer = nil
        fastingStartDate = 0
        fastingGoal = 0

        // End Live Activity
        Task {
            let finalState = FastingActivityAttributes.ContentState(elapsedTime: elapsedTime, currentZoneName: "Ended", progress: 1.0)
            await currentActivity?.end(using: finalState, dismissalPolicy: .immediate)
            print("Live Activity ended.")
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, self.fastingState == .fasting else { return }
            let startDate = Date(timeIntervalSince1970: self.fastingStartDate)
            self.elapsedTime = Date().timeIntervalSince(startDate)

            if Int(self.elapsedTime) % 30 == 0 { self.updateLiveActivity() }

            if self.elapsedTime >= self.fastingGoal { self.endFasting() }
        }
    }

    private func updateLiveActivity() {
        Task {
            let currentZone = FastingZone.allZones.filter { elapsedTime >= $0.duration }.last ?? .anabolic
            let progress = fastingGoal > 0 ? elapsedTime / fastingGoal : 0
            let updatedState = FastingActivityAttributes.ContentState(elapsedTime: elapsedTime, currentZoneName: currentZone.name, progress: progress)
            await currentActivity?.update(using: updatedState)
        }
    }
    
    private func sendContextToWatch() {
        let context: [String: Any] = [
            "fastingState": fastingState.rawValue,
            "fastingStartDate": fastingStartDate,
            "fastingGoal": fastingGoal
        ]
        connectivityManager.sendContext(context)
    }
    
    func getFastingGoal() -> TimeInterval {
        return fastingGoal
    }
    
    func getStartDate() -> Date {
        return Date(timeIntervalSince1970: fastingStartDate)
    }
    
    func updateStartTime(to newStartTime: Date) {
        fastingStartDate = newStartTime.timeIntervalSince1970
        
        // Recalculate elapsed time
        self.elapsedTime = Date().timeIntervalSince(newStartTime)
        
        // Update live activity and watch
        updateLiveActivity()
        sendContextToWatch()
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var fastingManager = FastingManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var isShowingCalendar = false
    @State private var isShowingPlanSelector = false
    @State private var isShowingProfile = false
    @State private var isShowingStartTimeEditor = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [.blue.opacity(0.3), .gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack {
                header
                Spacer()
                GaugeView(elapsedTime: fastingManager.elapsedTime, fastingGoal: fastingManager.getFastingGoal())
                    .frame(width: 300, height: 300)
                Spacer()
                FastingZoneInfoView(elapsedTime: fastingManager.elapsedTime)
                Spacer()
                controlButtons
                    .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $isShowingCalendar) { CalendarView() }
        .sheet(isPresented: $isShowingPlanSelector) { 
            PlanSelectorView()
                .environmentObject(fastingManager)
        }
        .sheet(isPresented: $isShowingProfile) { ProfileView() }
        .sheet(isPresented: $isShowingStartTimeEditor) {
            StartTimeEditorView()
                .environmentObject(fastingManager)
        }
        .fullScreenCover(isPresented: .constant(!hasCompletedOnboarding)) {
            OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var header: some View {
        HStack {
            Button(action: { isShowingProfile.toggle() }) {
                Image(systemName: "person.fill")
                    .font(.title2).foregroundColor(.white).padding()
                    .background(.ultraThinMaterial).clipShape(Circle())
            }
            Spacer()
            Button(action: { isShowingCalendar.toggle() }) {
                Image(systemName: "calendar")
                    .font(.title2).foregroundColor(.white).padding()
                    .background(.ultraThinMaterial).clipShape(Circle())
            }
        }.padding()
    }

    @ViewBuilder
    private var controlButtons: some View {
        if fastingManager.fastingState == .idle {
            glassButton(title: "Choose Fasting Plan", action: { isShowingPlanSelector.toggle() })
        } else {
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    glassButton(title: "Edit Start Time", action: { isShowingStartTimeEditor.toggle() })
                        .frame(maxWidth: .infinity)
                    glassButton(title: "End Fast", action: fastingManager.endFasting)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func glassButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            action()
        }) {
            Text(title)
                .font(.headline).foregroundColor(.white).padding()
                .frame(minWidth: 120)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], 
                                                     startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                .scaleEffect(1.0)
        }
        .buttonStyle(PressedButtonStyle())
    }
}

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Supporting Views

struct FastingZoneInfoView: View {
    let elapsedTime: TimeInterval
    @State private var currentMessage: String = ""
    @State private var messageTimer: Timer?
    @State private var messageType: Int = 0

    private var currentZone: FastingZone {
        return FastingZone.allZones.filter { elapsedTime >= $0.duration }.last ?? .anabolic
    }
    
    private var timeInCurrentZone: TimeInterval {
        let previousZone = FastingZone.allZones.filter { $0.duration < currentZone.duration }.last
        let startTime = previousZone?.duration ?? 0
        return elapsedTime - startTime
    }

    var body: some View {
        VStack(spacing: 15) {
            HStack {
                Text(currentZone.emoji)
                    .font(.title)
                    .scaleEffect(1.2)
                    .shadow(color: currentZone.color.opacity(0.5), radius: 3, x: 0, y: 2)
                Text(currentZone.name)
                    .font(.largeTitle).fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(colors: [currentZone.color, currentZone.color.opacity(0.7)], 
                                     startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            
            // Zone duration indicator
            if timeInCurrentZone > 0 {
                Text("In this zone for \(formatDuration(timeInCurrentZone))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
            }

            Text(currentMessage)
                .font(.subheadline).foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center).padding(.horizontal)
                .animation(.easeInOut(duration: 0.5), value: currentMessage)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(LinearGradient(colors: [currentZone.color.opacity(0.3), .clear], 
                                             startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
        .onAppear {
            updateMessage()
            startMessageTimer()
        }
        .onDisappear {
            messageTimer?.invalidate()
        }
        .onChange(of: currentZone.id) { _, _ in
            updateMessage()
        }
    }
    
    private func updateMessage() {
        // Add haptic feedback for zone changes
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        switch messageType % 3 {
        case 0:
            currentMessage = AIMessageManager.shared.generateFastingMessage(for: currentZone, messageType: .motivational)
        case 1:
            currentMessage = AIMessageManager.shared.generateFastingMessage(for: currentZone, messageType: .educational)
        case 2:
            currentMessage = AIMessageManager.shared.generateContextualMessage(for: currentZone, timeInZone: timeInCurrentZone)
        default:
            currentMessage = AIMessageManager.shared.generateFastingMessage(for: currentZone, messageType: .motivational)
        }
        messageType += 1
    }
    
    private func startMessageTimer() {
        messageTimer?.invalidate()
        messageTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            updateMessage()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}