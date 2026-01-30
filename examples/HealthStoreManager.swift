import HealthKit

// Target: iOS (and/or watchOS if querying on watch)
@MainActor
final class HealthStoreManager: ObservableObject {
    private let store = HKHealthStore()

    // Example types
    private let stepsType = HKQuantityType(.stepCount)
    private let heartRateType = HKQuantityType(.heartRate)

    @Published var stepsToday: Double?
    @Published var latestHeartRateBPM: Double?

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw NSError(domain: "HealthKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data unavailable"])
        }
        let read: Set<HKObjectType> = [stepsType, heartRateType]
        try await store.requestAuthorization(toShare: [], read: read)
    }

    func refreshStepsToday() async {
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, _ in
            let steps = result?.sumQuantity()?.doubleValue(for: .count())
            Task { @MainActor in self?.stepsToday = steps }
        }
        store.execute(query)
    }
}
