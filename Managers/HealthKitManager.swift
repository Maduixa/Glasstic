
import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    let healthStore = HKHealthStore()

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil) // Or a custom error
            return
        }

        let typesToShare: Set = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]

        let typesToRead: Set = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .bodyMass)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }

    func saveFast(startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        let fasting = HKCategorySample(type: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                                       value: 0, // Value is not used for intermittent fasting
                                       start: startDate,
                                       end: endDate)
        healthStore.save(fasting, withCompletion: completion)
    }
}
