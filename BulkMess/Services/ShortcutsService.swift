import Foundation
import UIKit

struct ShortcutsResult {
    let copiedCount: Int
    let remainingCount: Int
}

class ShortcutsService {
    static func importShortcut(from urlString: String, name: String) -> Bool {
        guard let encodedURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "shortcuts://import-shortcut?url=\(encodedURL)&name=\(encodedName)") else {
            return false
        }
        UIApplication.shared.open(url)
        return true
    }

    static func sendMessagesViaShortcuts(
        messages: [(phone: String, body: String)],
        campaignId: String? = nil,
        shortcutName: String = "BulkMess Send",
        maxPerBatch: Int = 500
    ) -> ShortcutsResult {
        guard !messages.isEmpty else { return ShortcutsResult(copiedCount: 0, remainingCount: 0) }

        let batch = Array(messages.prefix(maxPerBatch))
        let remaining = max(messages.count - batch.count, 0)

        let messagesPayload: [[String: String]] = batch.map { [
            "phone": $0.phone,
            "body": $0.body
        ] }

        var payload: [String: Any] = [
            "messages": messagesPayload
        ]

        // Add simplified campaign metadata if provided
        if let campaignId = campaignId {
            payload["campaignId"] = campaignId
            payload["totalMessages"] = messagesPayload.count
        }

        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let json = String(data: data, encoding: .utf8) else {
            return ShortcutsResult(copiedCount: 0, remainingCount: messages.count)
        }

        // Place JSON on the clipboard for the Shortcut to read
        UIPasteboard.general.string = json

        // Open the Shortcut by name
        let name = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName
        if let url = URL(string: "shortcuts://run-shortcut?name=\(name)") {
            UIApplication.shared.open(url)
        }

        return ShortcutsResult(copiedCount: batch.count, remainingCount: remaining)
    }

    // MARK: - Automated Sending (No Manual Approval)

    static func sendMessagesViaAutomatedShortcut(
        messages: [(phone: String, body: String)],
        shortcutName: String = "BulkMess Auto Send"
    ) -> Bool {
        guard !messages.isEmpty else { return false }

        let payload: [String: Any] = [
            "messages": messages.map { ["phone": $0.phone, "message": $0.body] }
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return false
        }

        // Place JSON on clipboard
        UIPasteboard.general.string = jsonString

        // Run the automated shortcut
        let encodedName = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName
        guard let url = URL(string: "shortcuts://run-shortcut?name=\(encodedName)") else { return false }

        UIApplication.shared.open(url)
        return true
    }

    static func sendMessagesViaBatchProcessor(
        messages: [(phone: String, body: String)],
        batchSize: Int = 10,
        delaySeconds: Double = 2.0,
        shortcutName: String = "BulkMess Batch Processor"
    ) -> Bool {
        guard !messages.isEmpty else { return false }

        let payload: [String: Any] = [
            "messages": messages.map { ["phone": $0.phone, "message": $0.body] },
            "batchSize": batchSize,
            "delaySeconds": delaySeconds
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return false
        }

        // Place JSON on clipboard
        UIPasteboard.general.string = jsonString

        // Run the batch processor shortcut
        let encodedName = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName
        guard let url = URL(string: "shortcuts://run-shortcut?name=\(encodedName)") else { return false }

        UIApplication.shared.open(url)
        return true
    }

    // MARK: - Message Response Detection

    /// Create shortcuts for automatic message response detection
    static func setupMessageResponseShortcuts() {
        // Set up clipboard monitoring shortcut
        let _ = """
        {
            "WFWorkflowName": "BulkMess Response Monitor",
            "WFWorkflowTypes": ["Watch", "NCWidget"],
            "WFWorkflowActions": [
                {
                    "WFWorkflowActionIdentifier": "is.workflow.actions.text",
                    "WFWorkflowActionParameters": {
                        "WFTextActionText": "bulkmess://record-response"
                    }
                },
                {
                    "WFWorkflowActionIdentifier": "is.workflow.actions.openurl",
                    "WFWorkflowActionParameters": {
                        "WFInput": "Text"
                    }
                }
            ]
        }
        """

        // This would typically be saved to a file and imported
        // For now, we'll provide the JSON structure for manual setup
    }

    /// Handle incoming message data from Shortcuts
    static func processIncomingMessageData(_ data: Data, completion: @escaping (Bool) -> Void) {
        guard let messageInfo = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let phoneNumber = messageInfo["phone"] as? String,
              let messageContent = messageInfo["message"] as? String else {
            completion(false)
            return
        }

        // Get the monitoring service and record the message
        if let monitoringService = getMonitoringService() {
            monitoringService.recordIncomingMessage(fromPhoneNumber: phoneNumber, content: messageContent)
            completion(true)
        } else {
            completion(false)
        }
    }

    /// Create URL scheme handler for Shortcuts integration
    static func handleShortcutURL(_ url: URL) -> Bool {
        guard url.scheme == "bulkmess",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        switch url.host {
        case "record-response":
            return handleRecordResponse(components: components)
        case "cancel-followup":
            return handleCancelFollowup(components: components)
        default:
            return false
        }
    }

    private static func handleRecordResponse(components: URLComponents) -> Bool {
        guard let phoneNumber = components.queryItems?.first(where: { $0.name == "phone" })?.value,
              let message = components.queryItems?.first(where: { $0.name == "message" })?.value else {
            return false
        }

        if let monitoringService = getMonitoringService() {
            monitoringService.recordIncomingMessage(fromPhoneNumber: phoneNumber, content: message)
            return true
        }
        return false
    }

    private static func handleCancelFollowup(components: URLComponents) -> Bool {
        guard let _ = components.queryItems?.first(where: { $0.name == "phone" })?.value else {
            return false
        }

        if getMonitoringService() != nil {
            // Find contact and cancel follow-ups
            // This would need access to the persistence layer
            return true
        }
        return false
    }

    private static func getMonitoringService() -> MessageMonitoringService? {
        return ServiceContainer.shared.resolve(MessageMonitoringService.self)
    }
}
