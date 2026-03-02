import SwiftUI
import WatchKit

@main
struct GlassticWatchApp: App {
    @StateObject private var watchConnectivity = WatchConnectivityService.shared
    @StateObject private var fastingStore = WatchFastingStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchConnectivity)
                .environmentObject(fastingStore)
        }
    }
}
