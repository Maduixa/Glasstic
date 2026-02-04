import SwiftData
import Foundation
import os.log

private let logger = Logger(subsystem: "com.glasstic", category: "DataService")

/// Errors that can occur during data service operations.
public enum DataServiceError: Error, LocalizedError {
    case containerCreationFailed(underlying: Error)
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
    
    public var errorDescription: String? {
        switch self {
        case .containerCreationFailed(let error):
            return "Failed to create data container: \(error.localizedDescription)"
        case .fetchFailed(let error):
            return "Failed to fetch data: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        }
    }
}

@MainActor
public final class DataService {
    public static let shared: DataService = {
        do {
            return try DataService()
        } catch {
            logger.error("Failed to create persistent DataService: \(error.localizedDescription). Falling back to in-memory storage.")
            return try! DataService(inMemory: true)
        }
    }()

    public let modelContainer: ModelContainer
    private let modelContext: ModelContext
    public let isInMemoryFallback: Bool

    private init(inMemory: Bool = false) throws {
        self.isInMemoryFallback = inMemory
        let schema = Schema([FastingSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
            
            if inMemory {
                logger.warning("DataService running in memory-only mode. Data will not persist across app launches.")
            }
        } catch {
            logger.error("ModelContainer creation failed: \(error.localizedDescription)")
            throw DataServiceError.containerCreationFailed(underlying: error)
        }
    }
    
    /// Creates a DataService for testing with in-memory storage.
    public static func makeForTesting() throws -> DataService {
        try DataService(inMemory: true)
    }

    public func fetchActiveFast() -> FastingSession? {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            logger.error("Failed to fetch active fast: \(error.localizedDescription)")
            return nil
        }
    }

    public func startFast() -> FastingSession {
        let session = FastingSession(startDate: Date())
        modelContext.insert(session)
        save()
        return session
    }

    public func endFast(_ session: FastingSession) {
        session.endDate = Date()
        save()
    }
    
    private func save() {
        do {
            try modelContext.save()
        } catch {
            logger.error("Failed to save context: \(error.localizedDescription)")
        }
    }
}
