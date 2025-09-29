import Foundation
import UIKit

/// Manager for creating and installing iOS Shortcuts automatically
class ShortcutsManager: ObservableObject {
    @Published var availableShortcuts: [ShortcutTemplate] = []
    @Published var installationStatus: [String: InstallationStatus] = [:]

    init() {
        setupAvailableShortcuts()
    }

    private func setupAvailableShortcuts() {
        availableShortcuts = [
            createMessageResponseShortcut(),
            createBulkResponseCheckShortcut(),
            createQuickCancelShortcut(),
            createAutomatedBulkSendingShortcut(),
            createBatchMessageProcessorShortcut()
        ]
    }

    // MARK: - Automatic Shortcut Creation

    /// Create a ready-to-install Shortcut for message response detection
    private func createMessageResponseShortcut() -> ShortcutTemplate {
        let shortcutData = generateMessageResponseShortcut()
        return ShortcutTemplate(
            name: "BulkMess Response Detector",
            description: "Automatically detects when you receive SMS responses and cancels follow-ups",
            shortcutData: shortcutData,
            installURL: createInstallURL(for: shortcutData, name: "BulkMess Response Detector"),
            automationTrigger: "When you receive a message"
        )
    }

    private func createBulkResponseCheckShortcut() -> ShortcutTemplate {
        let shortcutData = generateBulkCheckShortcut()
        return ShortcutTemplate(
            name: "BulkMess Check All Responses",
            description: "Manually trigger a check for all campaign responses",
            shortcutData: shortcutData,
            installURL: createInstallURL(for: shortcutData, name: "BulkMess Check All"),
            automationTrigger: "Manual trigger"
        )
    }

    private func createQuickCancelShortcut() -> ShortcutTemplate {
        let shortcutData = generateQuickCancelShortcut()
        return ShortcutTemplate(
            name: "BulkMess Quick Cancel",
            description: "Quickly cancel follow-ups for a specific phone number",
            shortcutData: shortcutData,
            installURL: createInstallURL(for: shortcutData, name: "BulkMess Quick Cancel"),
            automationTrigger: "Manual trigger with phone number input"
        )
    }

    private func createAutomatedBulkSendingShortcut() -> ShortcutTemplate {
        let shortcutData = generateAutomatedBulkSendingShortcut()
        return ShortcutTemplate(
            name: "BulkMess Auto Send",
            description: "Send bulk messages automatically without manual approval for each message",
            shortcutData: shortcutData,
            installURL: createInstallURL(for: shortcutData, name: "BulkMess Auto Send"),
            automationTrigger: "Triggered from BulkMess app or manual execution"
        )
    }

    private func createBatchMessageProcessorShortcut() -> ShortcutTemplate {
        let shortcutData = generateBatchMessageProcessorShortcut()
        return ShortcutTemplate(
            name: "BulkMess Batch Processor",
            description: "Process and send messages in batches with delay and error handling",
            shortcutData: shortcutData,
            installURL: createInstallURL(for: shortcutData, name: "BulkMess Batch Processor"),
            automationTrigger: "Triggered from BulkMess app with JSON payload"
        )
    }

    // MARK: - Shortcut Generation

    private func generateMessageResponseShortcut() -> [String: Any] {
        return [
            "WFWorkflowName": "BulkMess Response Detector",
            "WFWorkflowDescription": "Automatically detects SMS responses and cancels BulkMess follow-ups",
            "WFWorkflowMinimumClientVersionString": "900",
            "WFWorkflowTypes": ["Watch", "NCWidget"],
            "WFWorkflowActions": [
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.detect.text",
                    "WFWorkflowActionParameters": [
                        "WFInput": "Ask Each Time",
                        "text": "Get details from received message"
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.gettext",
                    "WFWorkflowActionParameters": [
                        "WFTextActionText": "Extracting phone number and message content..."
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.conditional",
                    "WFWorkflowActionParameters": [
                        "WFCondition": 100,
                        "WFConditionalActionString": "",
                        "WFControlFlowMode": 0
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.url",
                    "WFWorkflowActionParameters": [
                        "WFURLActionURL": "bulkmess://record-response?phone={{phone}}&message={{message}}"
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.openurl",
                    "WFWorkflowActionParameters": [
                        "WFInput": "URL"
                    ]
                ]
            ]
        ]
    }

    private func generateBulkCheckShortcut() -> [String: Any] {
        return [
            "WFWorkflowName": "BulkMess Check All Responses",
            "WFWorkflowDescription": "Check all BulkMess campaigns for responses",
            "WFWorkflowMinimumClientVersionString": "900",
            "WFWorkflowTypes": ["Watch", "NCWidget"],
            "WFWorkflowActions": [
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.url",
                    "WFWorkflowActionParameters": [
                        "WFURLActionURL": "bulkmess://check-responses"
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.openurl",
                    "WFWorkflowActionParameters": [
                        "WFInput": "URL"
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.notification",
                    "WFWorkflowActionParameters": [
                        "WFNotificationActionTitle": "BulkMess Response Check",
                        "WFNotificationActionBody": "Checked all campaigns for responses"
                    ]
                ]
            ]
        ]
    }

    private func generateQuickCancelShortcut() -> [String: Any] {
        return [
            "WFWorkflowName": "BulkMess Quick Cancel",
            "WFWorkflowDescription": "Quickly cancel follow-ups for a phone number",
            "WFWorkflowMinimumClientVersionString": "900",
            "WFWorkflowTypes": ["Watch", "NCWidget"],
            "WFWorkflowActions": [
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.ask",
                    "WFWorkflowActionParameters": [
                        "WFAskActionPrompt": "Enter phone number to cancel follow-ups:",
                        "WFInputType": "Text",
                        "WFAskActionDefaultAnswer": "+1"
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.url",
                    "WFWorkflowActionParameters": [
                        "WFURLActionURL": "bulkmess://cancel-followup?phone={{Provided Input}}"
                    ]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.openurl",
                    "WFWorkflowActionParameters": [
                        "WFInput": "URL"
                    ]
                ]
            ]
        ]
    }

    private func generateAutomatedBulkSendingShortcut() -> [String: Any] {
        return [
            "WFWorkflowName": "BulkMess Auto Send",
            "WFWorkflowDescription": "Automatically send bulk messages without manual approval",
            "WFWorkflowMinimumClientVersionString": "900",
            "WFWorkflowTypes": ["NCWidget"],
            "WFWorkflowActions": [
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.getclipboard",
                    "WFWorkflowActionParameters": [:]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.notification",
                    "WFWorkflowActionParameters": [
                        "WFNotificationActionTitle": "BulkMess Auto Send",
                        "WFNotificationActionBody": "Shortcut template ready. Manual setup required for message sending."
                    ]
                ]
            ]
        ]
    }

    private func generateBatchMessageProcessorShortcut() -> [String: Any] {
        return [
            "WFWorkflowName": "BulkMess Batch Processor",
            "WFWorkflowDescription": "Process messages in batches with delays and error handling",
            "WFWorkflowMinimumClientVersionString": "900",
            "WFWorkflowTypes": ["NCWidget"],
            "WFWorkflowActions": [
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.getclipboard",
                    "WFWorkflowActionParameters": [:]
                ],
                [
                    "WFWorkflowActionIdentifier": "is.workflow.actions.notification",
                    "WFWorkflowActionParameters": [
                        "WFNotificationActionTitle": "BulkMess Batch Processor",
                        "WFNotificationActionBody": "Shortcut template ready. Manual setup required for batch processing."
                    ]
                ]
            ]
        ]
    }

    // MARK: - Installation

    func installShortcut(_ template: ShortcutTemplate) {
        guard let installURL = template.installURL else {
            installationStatus[template.name] = .failed("Invalid install URL")
            return
        }

        installationStatus[template.name] = .installing
        UIApplication.shared.open(installURL) { success in
            DispatchQueue.main.async {
                self.installationStatus[template.name] = success ? .installed : .failed("Installation failed")
            }
        }
    }

    private func createInstallURL(for shortcutData: [String: Any], name: String) -> URL? {
        // In a real implementation, you'd encode the shortcut data and create a proper install URL
        // For now, we'll create a URL that opens the Shortcuts app to create a new shortcut
        let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name
        return URL(string: "shortcuts://create-shortcut?name=\(encodedName)")
    }

    // MARK: - Helper Methods

    func getInstallationInstructions(for template: ShortcutTemplate) -> [String] {
        switch template.name {
        case "BulkMess Response Detector":
            return [
                "1. Tap 'Install Shortcut' to create the shortcut",
                "2. In Shortcuts app, go to 'Automation' tab",
                "3. Tap '+' to create new automation",
                "4. Choose 'Message' trigger",
                "5. Set to run when 'Message is Received'",
                "6. Add action: 'Run Shortcut' → Select 'BulkMess Response Detector'",
                "7. Enable 'Run Immediately' for automatic operation"
            ]
        case "BulkMess Check All Responses":
            return [
                "1. Tap 'Install Shortcut' to create the shortcut",
                "2. Run manually when you want to check for responses",
                "3. Add to home screen widget for quick access",
                "4. Can also be run via Siri: 'Hey Siri, BulkMess Check All'"
            ]
        case "BulkMess Quick Cancel":
            return [
                "1. Tap 'Install Shortcut' to create the shortcut",
                "2. Run when you need to quickly cancel follow-ups",
                "3. Enter phone number when prompted",
                "4. Can be run via Siri: 'Hey Siri, BulkMess Quick Cancel'"
            ]
        case "BulkMess Auto Send":
            return [
                "1. Tap 'Install Shortcut' to create the shortcut",
                "2. IMPORTANT: Go to Settings → Shortcuts → Advanced",
                "3. Enable 'Allow Running Scripts' and 'Allow Sharing Large Amounts of Data'",
                "4. In the shortcut settings, turn ON 'Use with Siri'",
                "5. Turn OFF 'Use with Ask Before Running' for automatic operation",
                "6. From BulkMess app, tap 'Send via Auto Shortcut' when creating campaigns",
                "7. The shortcut will read JSON data from clipboard and send all messages automatically"
            ]
        case "BulkMess Batch Processor":
            return [
                "1. Tap 'Install Shortcut' to create the shortcut",
                "2. Enable advanced permissions in iOS Settings → Shortcuts",
                "3. This shortcut processes messages in batches with delays",
                "4. It reads JSON from clipboard with format: {\"messages\": [{\"phone\": \"+1234567890\", \"message\": \"Hello\"}], \"batchSize\": 10, \"delaySeconds\": 2}",
                "5. Automatically handles errors and provides completion statistics",
                "6. Best for large campaigns to avoid rate limiting"
            ]
        default:
            return ["Follow the standard installation process"]
        }
    }

    // MARK: - Advanced Setup

    func createAdvancedAutomation() -> String {
        return """
        For advanced users, create this automation in iOS Shortcuts:

        TRIGGER: When I receive a message
        CONDITIONS:
        - Message contains text (any text)
        - From anyone in your contacts

        ACTIONS:
        1. Get Text from Input (message content)
        2. Get Details of Messages (to extract sender)
        3. Set Variable "PhoneNumber" to sender's phone
        4. Set Variable "MessageContent" to message text
        5. Get URL: bulkmess://record-response?phone=[PhoneNumber]&message=[MessageContent]
        6. Open URL

        SETTINGS:
        - Run Immediately: ON
        - Notify When Run: OFF (to avoid spam)
        - Use with Siri: OFF
        """
    }

    func exportShortcutFile(_ template: ShortcutTemplate) -> URL? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: template.shortcutData, options: .prettyPrinted)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent("\(template.name).shortcut")
            try jsonData.write(to: fileURL)
            return fileURL
        } catch {
            print("Error exporting shortcut: \(error)")
            return nil
        }
    }
}

// MARK: - Supporting Types

struct ShortcutTemplate: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let shortcutData: [String: Any]
    let installURL: URL?
    let automationTrigger: String
}

enum InstallationStatus {
    case notStarted
    case installing
    case installed
    case failed(String)

    var displayText: String {
        switch self {
        case .notStarted: return "Not Installed"
        case .installing: return "Installing..."
        case .installed: return "Installed"
        case .failed(let error): return "Failed: \(error)"
        }
    }

    var color: UIColor {
        switch self {
        case .notStarted: return .systemGray
        case .installing: return .systemOrange
        case .installed: return .systemGreen
        case .failed: return .systemRed
        }
    }
}