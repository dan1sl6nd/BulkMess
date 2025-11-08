import Foundation

final class AnalyticsService {
    static let shared = AnalyticsService()
    private let queue = DispatchQueue(label: "com.bulkmess.analytics", qos: .utility)
    private var events: [Event] = []

    private init() {}

    struct Event: Codable {
        let name: String
        let properties: [String: String]?
        let timestamp: Date
    }

    func track(_ name: String, properties: [String: String]? = nil) {
        let event = Event(name: name, properties: properties, timestamp: Date())

        queue.async { [weak self] in
            self?.events.append(event)
        }
    }

    func fetchEvents() -> [Event] {
        queue.sync { events }
    }
}
