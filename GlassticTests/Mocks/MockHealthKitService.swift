import Foundation
import HealthKit
@testable import Glasstic

@MainActor
final class MockHealthKitService {
    var isAuthorized = false
    var shouldThrowError = false
    var errorToThrow: Error = HealthKitError.notAvailable

    // Track method calls
    var requestAuthorizationCallCount = 0
    var saveFastingWorkoutCallCount = 0
    var fetchRecentWeightTrendCallCount = 0

    // Mock data
    var mockWeightData: [WeightDataPoint] = []
    var savedWorkouts: [(startDate: Date, endDate: Date, duration: TimeInterval)] = []

    func reset() {
        isAuthorized = false
        shouldThrowError = false
        requestAuthorizationCallCount = 0
        saveFastingWorkoutCallCount = 0
        fetchRecentWeightTrendCallCount = 0
        mockWeightData = []
        savedWorkouts = []
    }

    func requestAuthorization() async throws {
        requestAuthorizationCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        isAuthorized = true
    }

    func fetchRecentWeightTrend() async throws -> [WeightDataPoint] {
        fetchRecentWeightTrendCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        return mockWeightData
    }

    func saveFastingWorkout(startDate: Date, endDate: Date, duration: TimeInterval) async throws {
        saveFastingWorkoutCallCount += 1
        if shouldThrowError {
            throw errorToThrow
        }
        savedWorkouts.append((startDate, endDate, duration))
    }
}
