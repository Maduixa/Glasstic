import SwiftUI
import ActivityKit
import Combine

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
        
        let hours = Int(goal / 3600)
        NotificationManager.shared.scheduleNotification(
            title: "Fasting Complete!",
            body: "You've completed your \(hours)-hour fast. Great job!",
            timeInterval: goal
        )

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
}

// MARK: - Main Content View
struct ContentView: View {
    @StateObject private var fastingManager = FastingManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    @State private var isShowingCalendar = false
    @State private var isShowingPlanSelector = false
    @State private var isShowingProfile = false

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
            glassButton(title: "End Fast", action: fastingManager.endFasting)
        }
    }

    private func glassButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline).foregroundColor(.white).padding()
                .frame(minWidth: 250)
                .background(.ultraThinMaterial).cornerRadius(20).shadow(radius: 5)
        }
    }
}

// MARK: - Supporting Views

struct FastingZoneInfoView: View {
    let elapsedTime: TimeInterval

    private var currentZone: FastingZone {
        return FastingZone.allZones.filter { elapsedTime >= $0.duration }.last ?? .anabolic
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(currentZone.name)
                .font(.largeTitle).fontWeight(.bold).foregroundColor(currentZone.color)

            Text(currentZone.trivia.randomElement() ?? "")
                .font(.subheadline).foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center).padding(.horizontal)
        }
        .padding().background(.ultraThinMaterial).cornerRadius(20).padding(.horizontal, 20)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}