import SwiftUI
import SwiftData
import GlassticFeature

@main
struct GlassticApp: App {
    @State private var store = FastingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
        .modelContainer(DataService.shared.modelContainer)
    }
}
