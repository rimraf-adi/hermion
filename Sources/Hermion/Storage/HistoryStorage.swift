import Foundation

public struct TranscriptionItem: Identifiable, Codable {
    public let id: UUID
    public let text: String
    public let timestamp: Date
    public let durationSeconds: Double
    
    public init(id: UUID = UUID(), text: String, timestamp: Date = Date(), durationSeconds: Double = 0.0) {
        self.id = id
        self.text = text
        self.timestamp = timestamp
        self.durationSeconds = durationSeconds
    }
}

public class HistoryStorage {
    public static let shared = HistoryStorage()
    private let key = "hermion_transcription_history"
    
    private init() {}
    
    public func loadHistory() -> [TranscriptionItem] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([TranscriptionItem].self, from: data) else {
            return []
        }
        return items
    }
    
    public func saveItem(_ item: TranscriptionItem) {
        var items = loadHistory()
        items.insert(item, at: 0)
        if items.count > 200 {
            items = Array(items.prefix(200))
        }
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    public func clearHistory() {
        UserDefaults.standard.removeObject(forKey: key)
    }
    
    public func deleteItem(id: UUID) {
        var items = loadHistory()
        items.removeAll(where: { $0.id == id })
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
