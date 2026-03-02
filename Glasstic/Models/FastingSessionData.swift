import Foundation
import SwiftData

@Model
final class FastingSessionData {
    var id: UUID
    var startDate: Date
    var endDate: Date?
    var note: String
    var editedDuration: TimeInterval?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date? = nil,
        note: String = "",
        editedDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.note = note
        self.editedDuration = editedDuration
    }

    var isActive: Bool {
        endDate == nil
    }

    var isCompleted: Bool {
        endDate != nil
    }

    var actualEndDate: Date {
        endDate ?? Date()
    }

    var duration: TimeInterval {
        if let editedDuration {
            return editedDuration
        }
        return actualEndDate.timeIntervalSince(startDate)
    }

    var durationHours: Double {
        duration / 3600
    }

    var calendarDay: Date {
        startDate.startOfDay
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }
}
