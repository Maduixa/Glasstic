import Foundation

struct TimeFormatter {
    static let shared = TimeFormatter()

    private let elapsedFormatter: DateComponentsFormatter

    init() {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = [.pad]
        elapsedFormatter = formatter
    }

    func shortElapsed(from start: Date, to end: Date) -> String {
        elapsedFormatter.string(from: start, to: end) ?? "00:00"
    }

    func string(from duration: TimeInterval) -> String {
        elapsedFormatter.string(from: duration) ?? "00:00"
    }
}
