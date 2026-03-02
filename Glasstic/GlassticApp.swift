import BackgroundTasks
import SwiftData
import SwiftUI
import GlassticFeature

@main
struct GlassticApp: App {
    @State private var store = GlassticFeature.FastingStore()
    @State private var theme = GlassticFeature.AppTheme()
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(theme)
                .onAppear {
                    appDelegate.store = store
                }
        }
        .modelContainer(DataService.shared.modelContainer)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background:
                scheduleBackgroundRefresh()
            case .active:
                // Refresh health data when app becomes active
                Task {
                    await store.refreshHealthProfile()
                }
            default:
                break
            }
        }
    }
    
    private func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.glasstic.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[GlassticApp] Failed to schedule background refresh: \(error)")
        }
    }
}

// MARK: - App Delegate

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    var store: GlassticFeature.FastingStore?
    
    static let backgroundRefreshIdentifier = "com.glasstic.refresh"
    static let backgroundProcessingIdentifier = "com.glasstic.processing"
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        registerBackgroundTasks()
        return true
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundRefreshIdentifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundRefresh(task: task as! BGAppRefreshTask)
            }
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundProcessingIdentifier,
            using: nil
        ) { task in
            Task { @MainActor in
                await self.handleBackgroundProcessing(task: task as! BGProcessingTask)
            }
        }
    }
    
    private func handleBackgroundRefresh(task: BGAppRefreshTask) async {
        // Schedule the next refresh
        scheduleNextRefresh()
        
        // Set up expiration handler
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform refresh
        if let store {
            await store.refreshHealthProfile()
        }
        
        task.setTaskCompleted(success: true)
    }
    
    private func handleBackgroundProcessing(task: BGProcessingTask) async {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        // Perform any heavy processing here (e.g., sync data)
        if let store {
            await store.refreshHealthProfile()
        }
        
        task.setTaskCompleted(success: true)
    }
    
    private func scheduleNextRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: Self.backgroundRefreshIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("[AppDelegate] Failed to schedule next refresh: \(error)")
        }
    }
}
