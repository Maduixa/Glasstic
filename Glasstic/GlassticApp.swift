import SwiftUI

@main
struct GlassticApp: App {
    @StateObject private var store = FastingStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(store)
        }
    }
}
