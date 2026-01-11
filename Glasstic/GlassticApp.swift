import SwiftUI
import SwiftData

@main
struct GlassticApp: App {
    @State private var store = FastingStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(store)
        }
        .modelContainer(DataService.shared.modelContainer)
    }
}
