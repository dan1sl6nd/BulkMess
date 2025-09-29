import Foundation

final class AnalyticsService {
    static let shared = AnalyticsService()
    private let userDefaultsKey = "AnalyticsEvents"

    private init() {}

    struct Event: Codable {
        let name: String
        let properties: [String: String]?
        let timestamp: Date
    }

    func track(_ name: String, properties: [String: String]? = nil) {
        let event = Event(name: name, properties: properties, timestamp: Date())
        print("[Analytics] \(name) props=\(properties ?? [:])")
        persist(event)
    }

    private func persist(_ event: Event) {
        var events = fetchEvents()
        events.append(event)
        if let data = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    func fetchEvents() -> [Event] {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let events = try? JSONDecoder().decode([Event].self, from: data) else {
            return []
        }
        return events
    }
}

