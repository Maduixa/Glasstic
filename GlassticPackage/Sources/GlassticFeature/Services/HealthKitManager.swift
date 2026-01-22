//
//  HealthKitManager.swift
//  Glasstic
//
//  Manages HealthKit integration for reading and writing fasting-related health data.
//  Handles authorization, reading body metrics, and saving fasting sessions.
//

import Foundation
import HealthKit

/// Manages all HealthKit interactions for the Glasstic fasting app.
/// Handles authorization, reading health metrics, and saving fasting data.
@MainActor
public final class HealthKitManager: Sendable {
    
    // MARK: - Singleton
    
    public static let shared = HealthKitManager()
    
    // MARK: - Properties
    
    private let healthStore: HKHealthStore?
    
    /// Whether HealthKit is available on this device
    public var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    /// Current authorization status for fasting data
    public private(set) var authorizationStatus: AuthorizationStatus = .notDetermined
    
    // MARK: - Types
    
    public enum AuthorizationStatus: Sendable {
        case notDetermined
        case authorized
        case denied
        case unavailable
    }
    
    public enum HealthKitError: Error, LocalizedError {
        case unavailable
        case authorizationDenied
        case saveFailed(Error)
        case readFailed(Error)
        case invalidData
        
        public var errorDescription: String? {
            switch self {
            case .unavailable:
                return "HealthKit is not available on this device."
            case .authorizationDenied:
                return "HealthKit authorization was denied."
            case .saveFailed(let error):
                return "Failed to save to HealthKit: \(error.localizedDescription)"
            case .readFailed(let error):
                return "Failed to read from HealthKit: \(error.localizedDescription)"
            case .invalidData:
                return "Invalid health data."
            }
        }
    }
    
    // MARK: - Health Data Types
    
    /// Types we want to read from HealthKit
    private var typesToRead: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        
        // Body measurements for calorie estimation
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        if let height = HKQuantityType.quantityType(forIdentifier: .height) {
            types.insert(height)
        }
        if let age = HKCharacteristicType.characteristicType(forIdentifier: .dateOfBirth) {
            types.insert(age)
        }
        if let sex = HKCharacteristicType.characteristicType(forIdentifier: .biologicalSex) {
            types.insert(sex)
        }
        
        // Activity for correlation
        if let activeEnergy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let basalEnergy = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) {
            types.insert(basalEnergy)
        }
        
        // Dietary data for fasting window detection
        if let dietaryEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(dietaryEnergy)
        }
        
        return types
    }
    
    /// Types we want to write to HealthKit
    private var typesToWrite: Set<HKSampleType> {
        var types = Set<HKSampleType>()
        
        // We'll write fasting as a custom category or workout
        // For now, we can track it as dietary energy consumed = 0 during fasting periods
        // Or use a workout type for extended fasts
        
        if let dietaryEnergy = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(dietaryEnergy)
        }
        
        return types
    }
    
    // MARK: - Initialization
    
    private init() {
        if HKHealthStore.isHealthDataAvailable() {
            healthStore = HKHealthStore()
        } else {
            healthStore = nil
            authorizationStatus = .unavailable
        }
    }
    
    // MARK: - Authorization
    
    /// Request HealthKit authorization
    public func requestAuthorization() async throws {
        guard let healthStore else {
            authorizationStatus = .unavailable
            throw HealthKitError.unavailable
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
            
            // Check if we got authorization for our main types
            if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                let status = healthStore.authorizationStatus(for: bodyMass)
                switch status {
                case .sharingAuthorized:
                    authorizationStatus = .authorized
                case .sharingDenied:
                    authorizationStatus = .denied
                case .notDetermined:
                    authorizationStatus = .notDetermined
                @unknown default:
                    authorizationStatus = .notDetermined
                }
            }
        } catch {
            authorizationStatus = .denied
            throw HealthKitError.authorizationDenied
        }
    }
    
    /// Check if we have authorization without prompting
    public func checkAuthorizationStatus() -> AuthorizationStatus {
        guard let healthStore else { return .unavailable }
        
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            let status = healthStore.authorizationStatus(for: bodyMass)
            switch status {
            case .sharingAuthorized:
                return .authorized
            case .sharingDenied:
                return .denied
            case .notDetermined:
                return .notDetermined
            @unknown default:
                return .notDetermined
            }
        }
        return .notDetermined
    }
    
    // MARK: - Reading Data
    
    /// Fetch the user's most recent body weight
    public func fetchBodyWeight() async throws -> Double? {
        guard let healthStore else { throw HealthKitError.unavailable }
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.readFailed(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weightInKg)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch the user's height
    public func fetchHeight() async throws -> Double? {
        guard let healthStore else { throw HealthKitError.unavailable }
        guard let heightType = HKQuantityType.quantityType(forIdentifier: .height) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.readFailed(error))
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let heightInCm = sample.quantity.doubleValue(for: .meterUnit(with: .centi))
                continuation.resume(returning: heightInCm)
            }
            
            healthStore.execute(query)
        }
    }
    
    /// Fetch the user's age based on date of birth
    public func fetchAge() -> Int? {
        guard let healthStore else { return nil }
        
        do {
            let dateOfBirth = try healthStore.dateOfBirthComponents()
            guard let birthYear = dateOfBirth.year else { return nil }
            
            let currentYear = Calendar.current.component(.year, from: Date())
            return currentYear - birthYear
        } catch {
            return nil
        }
    }
    
    /// Fetch the user's biological sex
    public func fetchBiologicalSex() -> HKBiologicalSex? {
        guard let healthStore else { return nil }
        
        do {
            let biologicalSex = try healthStore.biologicalSex()
            return biologicalSex.biologicalSex
        } catch {
            return nil
        }
    }
    
    /// Fetch basal metabolic rate estimate from recent data
    public func fetchBasalEnergyBurned(for date: Date = Date()) async throws -> Double? {
        guard let healthStore else { throw HealthKitError.unavailable }
        guard let basalType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) else {
            return nil
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: basalType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: HealthKitError.readFailed(error))
                    return
                }
                
                guard let sum = statistics?.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let calories = sum.doubleValue(for: .kilocalorie())
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - User Profile
    
    /// Comprehensive user health profile for calorie calculations
    public struct UserHealthProfile: Sendable {
        public let weightKg: Double?
        public let heightCm: Double?
        public let age: Int?
        public let biologicalSex: HKBiologicalSex?
        public let estimatedBMR: Double?
        
        /// Calculate BMR using Mifflin-St Jeor equation
        public var calculatedBMR: Double? {
            guard let weight = weightKg,
                  let height = heightCm,
                  let age = age else {
                return nil
            }
            
            // Mifflin-St Jeor Equation
            let baseBMR = (10 * weight) + (6.25 * height) - (5 * Double(age))
            
            switch biologicalSex {
            case .male:
                return baseBMR + 5
            case .female:
                return baseBMR - 161
            default:
                // Use average if sex unknown
                return baseBMR - 78
            }
        }
    }
    
    /// Fetch complete user health profile
    public func fetchUserProfile() async throws -> UserHealthProfile {
        async let weight = fetchBodyWeight()
        async let height = fetchHeight()
        async let basal = fetchBasalEnergyBurned()
        
        let age = fetchAge()
        let sex = fetchBiologicalSex()
        
        return try await UserHealthProfile(
            weightKg: weight,
            heightCm: height,
            age: age,
            biologicalSex: sex,
            estimatedBMR: basal
        )
    }
    
    // MARK: - Writing Fasting Data
    
    /// Save a completed fasting session to HealthKit
    /// Currently saves as a note in dietary energy (0 calories consumed during fast)
    public func saveFastingSession(
        startDate: Date,
        endDate: Date,
        caloriesBurned: Double
    ) async throws {
        guard let healthStore else { throw HealthKitError.unavailable }
        
        // We don't actually want to save 0 dietary energy as it could confuse users
        // Instead, we could use the app's own storage or wait for Apple to add
        // a proper fasting data type
        
        // For now, we'll just log it - in a real app you might:
        // 1. Save to a custom HealthKit workout type
        // 2. Use CloudKit for cross-device sync
        // 3. Wait for Apple's intermittent fasting features
        
        print("[HealthKit] Would save fasting session: \(startDate) - \(endDate), \(caloriesBurned) kcal burned")
    }
    
    // MARK: - Background Delivery
    
    /// Enable background delivery for health data updates
    public func enableBackgroundDelivery() async {
        guard let healthStore else { return }
        
        // Enable background delivery for body mass changes
        if let bodyMass = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            do {
                try await healthStore.enableBackgroundDelivery(for: bodyMass, frequency: .daily)
            } catch {
                print("[HealthKit] Failed to enable background delivery for body mass: \(error)")
            }
        }
    }
}

// MARK: - Convenience Extensions

extension HKBiologicalSex {
    public var displayString: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Other"
        case .notSet: return "Not Set"
        @unknown default: return "Unknown"
        }
    }
}
