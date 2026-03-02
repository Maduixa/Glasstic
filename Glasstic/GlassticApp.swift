import SwiftUI
import SwiftData
import GlassticFeature

@main
struct GlassticApp: App {
    @State private var store = GlassticFeature.FastingStore()
    @State private var theme = GlassticFeature.AppTheme()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(theme)
        }
        .modelContainer(DataService.shared.modelContainer)
    }
}
