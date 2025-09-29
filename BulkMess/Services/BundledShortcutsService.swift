import Foundation
import UIKit

enum BundledShortcutsService {
    static func bundledShortcutURL(preferredName: String?) -> URL? {
        let bundle = Bundle.main
        // Try preferred name first
        if let name = preferredName, let url = bundle.url(forResource: name, withExtension: "shortcut") {
            return url
        }
        // Try common sanitized variants
        if let name = preferredName?.replacingOccurrences(of: " ", with: "_"),
           let url = bundle.url(forResource: name, withExtension: "shortcut") {
            return url
        }
        // Fallback: return first .shortcut in bundle, if any
        let candidates = bundle.paths(forResourcesOfType: "shortcut", inDirectory: nil)
        if let path = candidates.first { return URL(fileURLWithPath: path) }
        return nil
    }
}

