import Foundation
import HealthKit

@MainActor
final class HealthKitService {
    static let shared = HealthKitService()

    private let healthStore = HKHealthStore()
    private(set) var isAuthorized = false

    private init() {}

    // MARK: - Authorization

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }

        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidType
        }

        let typesToRead: Set<HKObjectType> = [bodyMassType]
        let typesToWrite: Set<HKSampleType> = [HKObjectType.workoutType()]

        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        isAuthorized = true
    }

    // MARK: - Read Weight Data

    func fetchRecentWeightTrend() async throws -> [WeightDataPoint] {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.invalidType
        }

        let now = Date()
        guard let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) else {
            throw HealthKitError.invalidType
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: thirtyDaysAgo,
            end: now,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let dataPoints = samples.map { sample in
                    WeightDataPoint(
                        date: sample.startDate,
                        weight: sample.quantity.doubleValue(for: .pound())
                    )
                }

                continuation.resume(returning: dataPoints)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Write Fasting Workouts

    func saveFastingWorkout(startDate: Date, endDate: Date, duration: TimeInterval) async throws {
        let workout = HKWorkout(
            activityType: .other,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: [
                "FastingWorkout": true,
                "DurationHours": duration / 3600
            ]
        )

        try await healthStore.save(workout)
    }
}

// MARK: - Supporting Types

struct WeightDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double // in pounds
}

enum HealthKitError: LocalizedError {
    case notAvailable
    case invalidType
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .invalidType:
            return "Invalid HealthKit data type"
        case .unauthorized:
            return "HealthKit authorization required"
        }
    }
}
