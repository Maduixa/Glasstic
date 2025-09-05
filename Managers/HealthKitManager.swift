
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

        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(false, nil)
            return
        }

        var typesToShare: Set<HKSampleType> = [mindfulType]
        var typesToRead: Set<HKObjectType> = [mindfulType]

        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            typesToRead.insert(bodyMass)
        }
        if let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate) {
            typesToRead.insert(heartRate)
        }

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead, completion: completion)
    }

    func saveFast(startDate: Date, endDate: Date, completion: @escaping (Bool, Error?) -> Void) {
        guard let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession) else {
            completion(false, nil)
            return
        }

        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate
        )
        healthStore.save(sample, withCompletion: completion)
    }
}
