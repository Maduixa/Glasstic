import Foundation

struct PersistedAppState: Codable {
    var sessions: [FastingSession]
    var thresholds: FastingThresholds
    var selectedThemeID: UUID?
}

struct JSONFileStore<Value: Codable> {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileName: String, directoryName: String = "Glasstic") {
        let fileManager = FileManager.default
        let supportURLs = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let documentURLs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let baseURL = supportURLs.first ?? documentURLs.first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let directoryURL = baseURL.appendingPathComponent(directoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        self.fileURL = directoryURL.appendingPathComponent(fileName)
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func load(defaultValue: Value) -> Value {
        guard let data = try? Data(contentsOf: fileURL) else {
            return defaultValue
        }
        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            return defaultValue
        }
    }

    func save(_ value: Value) {
        do {
            let data = try encoder.encode(value)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            #if DEBUG
            NSLog("Failed to persist \(fileURL.lastPathComponent): \(error.localizedDescription)")
            #endif
        }
    }
}
