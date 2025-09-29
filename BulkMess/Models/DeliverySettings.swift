import Foundation

enum DeliveryMode: String, CaseIterable, Identifiable {
    case interactive // Messages composer (user taps Send)
    case shortcuts   // Native Shortcuts app
    case simulated   // In-app simulation (for testing)

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .interactive: return "Interactive via Messages"
        case .shortcuts: return "Shortcuts"
        case .simulated: return "Simulated"
        }
    }
}

class DeliverySettings: ObservableObject {
    private let key = "DeliveryMode"
    private let batchKey = "ShortcutsBatchSize"
    private let nameKey = "ShortcutsName"
    private let importURLKey = "ShortcutsImportURL"

    @Published var mode: DeliveryMode {
        didSet { UserDefaults.standard.set(mode.rawValue, forKey: key) }
    }

    @Published var shortcutsBatchSize: Int {
        didSet {
            let clamped = max(10, min(shortcutsBatchSize, 2000))
            if clamped != shortcutsBatchSize { shortcutsBatchSize = clamped; return }
            UserDefaults.standard.set(shortcutsBatchSize, forKey: batchKey)
        }
    }

    @Published var shortcutName: String {
        didSet { UserDefaults.standard.set(shortcutName, forKey: nameKey) }
    }

    @Published var shortcutImportURL: String {
        didSet { UserDefaults.standard.set(shortcutImportURL, forKey: importURLKey) }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: key), let m = DeliveryMode(rawValue: raw) {
            self.mode = m
        } else {
            self.mode = .interactive
        }

        let stored = UserDefaults.standard.integer(forKey: batchKey)
        self.shortcutsBatchSize = stored > 0 ? stored : 500

        self.shortcutName = UserDefaults.standard.string(forKey: nameKey) ?? "BulkMess Send"
        self.shortcutImportURL = UserDefaults.standard.string(forKey: importURLKey) ?? ""
    }
}
