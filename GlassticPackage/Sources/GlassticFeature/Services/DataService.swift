import SwiftData
import Foundation

@MainActor
public final class DataService {
    public static let shared = DataService()

    public let modelContainer: ModelContainer
    private let modelContext: ModelContext

    private init() {
        let schema = Schema([FastingSession.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
            modelContext = ModelContext(modelContainer)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    public func fetchActiveFast() -> FastingSession? {
        let descriptor = FetchDescriptor<FastingSession>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    public func startFast() -> FastingSession {
        let session = FastingSession(startDate: Date())
        modelContext.insert(session)
        try? modelContext.save()
        return session
    }

    public func endFast(_ session: FastingSession) {
        session.endDate = Date()
        try? modelContext.save()
    }
}
