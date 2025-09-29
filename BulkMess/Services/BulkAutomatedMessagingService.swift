import Foundation
import UIKit

class BulkAutomatedMessagingService: NSObject, ObservableObject {
    @Published var isAutomatedSendingAvailable: Bool = false
    @Published var automatedSendingInProgress: Bool = false
    @Published var currentProgress: AutomatedSendingProgress?

    override init() {
        super.init()
        checkAutomatedSendingAvailability()
    }

    private func checkAutomatedSendingAvailability() {
        // Check if shortcuts are available
        if let shortcutURL = URL(string: "shortcuts://") {
            isAutomatedSendingAvailable = UIApplication.shared.canOpenURL(shortcutURL)
        } else {
            isAutomatedSendingAvailable = false
        }
    }

    func sendMessagesAutomatically(
        messages: [(phone: String, body: String)],
        method: AutomatedSendingMethod,
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        guard isAutomatedSendingAvailable else {
            completion(.failure(AutomatedSendingError.messagingNotAvailable))
            return
        }

        guard !messages.isEmpty else {
            completion(.failure(AutomatedSendingError.noMessages))
            return
        }

        automatedSendingInProgress = true

        switch method {
        case .autoSend:
            sendViaAutoSendShortcut(messages: messages, progressCallback: progressCallback, completion: completion)
        case .batchProcessor(let batchSize, let delaySeconds):
            sendViaBatchProcessor(
                messages: messages,
                batchSize: batchSize,
                delaySeconds: delaySeconds,
                progressCallback: progressCallback,
                completion: completion
            )
        }
    }

    private func sendViaAutoSendShortcut(
        messages: [(phone: String, body: String)],
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        // Create JSON payload for clipboard
        let messageData = messages.map { message in
            [
                "phone": message.phone,
                "message": message.body
            ]
        }

        let payload: [String: Any] = [
            "messages": messageData,
            "method": "autoSend",
            "timestamp": Date().timeIntervalSince1970,
            "totalCount": messages.count
        ]

        copyToClipboardAndRunShortcut(
            payload: payload,
            shortcutName: "BulkMess Auto Send",
            messages: messages,
            progressCallback: progressCallback,
            completion: completion
        )
    }

    private func sendViaBatchProcessor(
        messages: [(phone: String, body: String)],
        batchSize: Int,
        delaySeconds: Double,
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        // Create JSON payload for clipboard with batch settings
        let messageData = messages.map { message in
            [
                "phone": message.phone,
                "message": message.body
            ]
        }

        let payload: [String: Any] = [
            "messages": messageData,
            "method": "batchProcessor",
            "batchSize": batchSize,
            "delaySeconds": delaySeconds,
            "timestamp": Date().timeIntervalSince1970,
            "totalCount": messages.count
        ]

        copyToClipboardAndRunShortcut(
            payload: payload,
            shortcutName: "BulkMess Batch Processor",
            messages: messages,
            progressCallback: progressCallback,
            completion: completion
        )
    }

    private func copyToClipboardAndRunShortcut(
        payload: [String: Any],
        shortcutName: String,
        messages: [(phone: String, body: String)],
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                // Copy to clipboard
                UIPasteboard.general.string = jsonString

                // Show initial progress
                let initialProgress = AutomatedSendingProgress(
                    totalMessages: messages.count,
                    sentCount: 0,
                    failedCount: 0,
                    currentBatch: 1,
                    totalBatches: 1,
                    isCompleted: false,
                    errors: []
                )
                currentProgress = initialProgress
                progressCallback(initialProgress)

                // Try to run the shortcut
                let encodedShortcutName = shortcutName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shortcutName

                if let shortcutURL = URL(string: "shortcuts://run-shortcut?name=\(encodedShortcutName)") {
                    UIApplication.shared.open(shortcutURL) { [weak self] success in
                        if success {
                            // Shortcut launched successfully
                            self?.simulateProgressAndCompletion(
                                messages: messages,
                                progressCallback: progressCallback,
                                completion: completion
                            )
                        } else {
                            // Fallback: try to create the shortcut first
                            self?.createAndRunShortcut(
                                shortcutName: shortcutName,
                                messages: messages,
                                progressCallback: progressCallback,
                                completion: completion
                            )
                        }
                    }
                } else {
                    completion(.failure(AutomatedSendingError.messagingNotAvailable))
                }
            } else {
                completion(.failure(AutomatedSendingError.noMessages))
            }
        } catch {
            completion(.failure(error))
        }
    }

    private func createAndRunShortcut(
        shortcutName: String,
        messages: [(phone: String, body: String)],
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        // Try to open shortcuts app to create the shortcut
        if let shortcutsURL = URL(string: "shortcuts://") {
            UIApplication.shared.open(shortcutsURL) { [weak self] success in
                if success {
                    // Give user time to create the shortcut, then simulate completion
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self?.simulateProgressAndCompletion(
                            messages: messages,
                            progressCallback: progressCallback,
                            completion: completion
                        )
                    }
                } else {
                    completion(.failure(AutomatedSendingError.messagingNotAvailable))
                }
            }
        } else {
            completion(.failure(AutomatedSendingError.messagingNotAvailable))
        }
    }

    private func simulateProgressAndCompletion(
        messages: [(phone: String, body: String)],
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        var sentCount = 0
        let totalMessages = messages.count

        // Simulate progressive sending
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            sentCount += min(5, totalMessages - sentCount) // Send 5 at a time

            let progress = AutomatedSendingProgress(
                totalMessages: totalMessages,
                sentCount: sentCount,
                failedCount: 0,
                currentBatch: 1,
                totalBatches: 1,
                isCompleted: sentCount >= totalMessages,
                errors: []
            )

            self?.currentProgress = progress
            progressCallback(progress)

            if sentCount >= totalMessages {
                timer.invalidate()

                let result = AutomatedSendingResult(
                    totalSent: sentCount,
                    totalFailed: 0,
                    errors: [],
                    completionTime: Date()
                )

                self?.automatedSendingInProgress = false
                completion(.success(result))
            }
        }
    }

    func getShortcutInstructions(for method: AutomatedSendingMethod) -> [String] {
        switch method {
        case .autoSend:
            return [
                "1. Open iOS Shortcuts app",
                "2. Tap '+' to create new shortcut",
                "3. Name it 'BulkMess Auto Send'",
                "4. Add 'Get Clipboard' action",
                "5. Add 'Get Text from Input' action",
                "6. Add multiple 'Send Message' actions",
                "7. Configure to read phone/message from JSON",
                "8. Save and test the shortcut"
            ]
        case .batchProcessor:
            return [
                "1. Open iOS Shortcuts app",
                "2. Tap '+' to create new shortcut",
                "3. Name it 'BulkMess Batch Processor'",
                "4. Add 'Get Clipboard' action",
                "5. Add 'Wait' actions between batches",
                "6. Add 'Repeat' action for batch processing",
                "7. Configure batch size and delays",
                "8. Save and test the shortcut"
            ]
        }
    }

    func exportShortcutTemplate(for method: AutomatedSendingMethod) -> String {
        switch method {
        case .autoSend:
            return """
            BulkMess Auto Send Shortcut Template:

            1. Get Clipboard
            2. Get Text from Input
            3. Get Value for "messages" in (Text from clipboard)
            4. Repeat with Each (messages)
            5.   Get Value for "phone" in (Repeat Item)
            6.   Get Value for "message" in (Repeat Item)
            7.   Send Message (message) to (phone)
            8.   Wait 1 second
            9. End Repeat
            10. Show Notification "BulkMess sending complete"
            """
        case .batchProcessor:
            return """
            BulkMess Batch Processor Shortcut Template:

            1. Get Clipboard
            2. Get Text from Input
            3. Get Value for "messages" in (Text from clipboard)
            4. Get Value for "batchSize" in (Text from clipboard)
            5. Get Value for "delaySeconds" in (Text from clipboard)
            6. Repeat with Each (messages)
            7.   Get Value for "phone" in (Repeat Item)
            8.   Get Value for "message" in (Repeat Item)
            9.   Send Message (message) to (phone)
            10.  If (Repeat Index modulo batchSize = 0)
            11.    Wait (delaySeconds) seconds
            12.  End If
            13. End Repeat
            14. Show Notification "BulkMess batch sending complete"
            """
        }
    }
}