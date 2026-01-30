import WidgetKit
import SwiftUI

// Target: watchOS Widget extension (complication)
struct StepsEntry: TimelineEntry {
    let date: Date
    let steps: Int
}

struct StepsProvider: TimelineProvider {
    func placeholder(in context: Context) -> StepsEntry { .init(date: .now, steps: 1000) }
    func getSnapshot(in context: Context, completion: @escaping (StepsEntry) -> Void) {
        completion(.init(date: .now, steps: 1000))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<StepsEntry>) -> Void) {
        let entry = StepsEntry(date: .now, steps: 1234) // TODO: fetch
        let next = Calendar.current.date(byAdding: .minute, value: 60, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StepsComplicationView: View {
    var entry: StepsEntry
    var body: some View {
        Text("\(entry.steps)")
    }
}

@main
struct StepsComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StepsComplication", provider: StepsProvider()) { entry in
            StepsComplicationView(entry: entry)
        }
        .supportedFamilies([.accessoryCircular, .accessoryCorner])
    }
}
