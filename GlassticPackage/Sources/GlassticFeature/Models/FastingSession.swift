import SwiftData
import Foundation

@Model
public final class FastingSession {
    public var id: UUID
    public var startDate: Date
    public var endDate: Date?

    public init(startDate: Date = Date(), endDate: Date? = nil) {
        self.id = UUID()
        self.startDate = startDate
        self.endDate = endDate
    }

    public var isActive: Bool {
        endDate == nil
    }

    public var duration: TimeInterval {
        let end = endDate ?? Date()
        return end.timeIntervalSince(startDate)
    }
}
