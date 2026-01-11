import Foundation
@testable import Glasstic

// MARK: - Test Data Builders

extension FastingSessionData {
    static func makeTest(
        id: UUID = UUID(),
        startDate: Date = Date(),
        endDate: Date? = nil,
        note: String = "Test session",
        editedDuration: TimeInterval? = nil
    ) -> FastingSessionData {
        FastingSessionData(
            id: id,
            startDate: startDate,
            endDate: endDate,
            note: note,
            editedDuration: editedDuration
        )
    }

    static func makeCompleted(
        startDate: Date = Date().addingTimeInterval(-86400), // 1 day ago
        duration: TimeInterval = 16 * 3600, // 16 hours
        note: String = "Completed test"
    ) -> FastingSessionData {
        FastingSessionData(
            startDate: startDate,
            endDate: startDate.addingTimeInterval(duration),
            note: note
        )
    }

    static func makeActive(
        startDate: Date = Date().addingTimeInterval(-3600), // 1 hour ago
        note: String = "Active test"
    ) -> FastingSessionData {
        FastingSessionData(
            startDate: startDate,
            endDate: nil,
            note: note
        )
    }
}

extension FastingThresholds {
    static func makeTest(
        postMealEndHours: Double = 4,
        earlyFastingEndHours: Double = 12,
        fatBurningEndHours: Double = 18
    ) -> FastingThresholds {
        FastingThresholds(
            postMealEndHours: postMealEndHours,
            earlyFastingEndHours: earlyFastingEndHours,
            fatBurningEndHours: fatBurningEndHours
        )
    }
}

extension WeightDataPoint {
    static func makeTest(
        date: Date = Date(),
        weight: Double = 180.0
    ) -> WeightDataPoint {
        WeightDataPoint(date: date, weight: weight)
    }
}

// MARK: - Date Helpers

extension Date {
    static func daysAgo(_ days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date())!
    }

    static func hoursAgo(_ hours: Int) -> Date {
        Date().addingTimeInterval(-TimeInterval(hours * 3600))
    }

    static func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }
}

// MARK: - Assertion Helpers

import XCTest

func XCTAssertEqualWithAccuracy(
    _ expression1: TimeInterval,
    _ expression2: TimeInterval,
    accuracy: TimeInterval = 1.0,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let difference = abs(expression1 - expression2)
    XCTAssertLessThanOrEqual(
        difference,
        accuracy,
        message.isEmpty ? "Expected \(expression1) to equal \(expression2) within \(accuracy)" : message,
        file: file,
        line: line
    )
}
