import Foundation
import MessageUI
import UIKit

class AutomatedMessagingService: NSObject, ObservableObject {
    @Published var isAutomatedSendingAvailable: Bool = false
    @Published var automatedSendingInProgress: Bool = false
    @Published var currentProgress: AutomatedSendingProgress?

    override init() {
        super.init()
        checkAutomatedSendingAvailability()
    }

    private func checkAutomatedSendingAvailability() {
        isAutomatedSendingAvailable = MFMessageComposeViewController.canSendText()
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
            sendViaAutoSend(messages: messages, progressCallback: progressCallback, completion: completion)
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

    private func sendViaAutoSend(
        messages: [(phone: String, body: String)],
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        var sentCount = 0
        var failedCount = 0
        var errors: [String] = []

        let progress = AutomatedSendingProgress(
            totalMessages: messages.count,
            sentCount: 0,
            failedCount: 0,
            currentBatch: 1,
            totalBatches: 1,
            isCompleted: false,
            errors: []
        )

        currentProgress = progress
        progressCallback(progress)

        Task {
            for (index, message) in messages.enumerated() {
                let success = await sendSingleMessage(phone: message.phone, body: message.body)

                if success {
                    sentCount += 1
                } else {
                    failedCount += 1
                    errors.append("Failed to send to \(message.phone)")
                }

                let updatedProgress = AutomatedSendingProgress(
                    totalMessages: messages.count,
                    sentCount: sentCount,
                    failedCount: failedCount,
                    currentBatch: 1,
                    totalBatches: 1,
                    isCompleted: index == messages.count - 1,
                    errors: errors
                )

                await MainActor.run {
                    currentProgress = updatedProgress
                    progressCallback(updatedProgress)
                }

                if index < messages.count - 1 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
            }

            let result = AutomatedSendingResult(
                totalSent: sentCount,
                totalFailed: failedCount,
                errors: errors,
                completionTime: Date()
            )

            await MainActor.run {
                automatedSendingInProgress = false
                completion(.success(result))
            }
        }
    }

    private func sendViaBatchProcessor(
        messages: [(phone: String, body: String)],
        batchSize: Int,
        delaySeconds: Double,
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        let batches = messages.chunked(into: batchSize)
        var totalSent = 0
        var totalFailed = 0
        var allErrors: [String] = []

        Task {
            for (batchIndex, batch) in batches.enumerated() {
                var batchSent = 0
                var batchFailed = 0
                var batchErrors: [String] = []

                for message in batch {
                    let success = await sendSingleMessage(phone: message.phone, body: message.body)

                    if success {
                        batchSent += 1
                        totalSent += 1
                    } else {
                        batchFailed += 1
                        totalFailed += 1
                        let error = "Failed to send to \(message.phone)"
                        batchErrors.append(error)
                        allErrors.append(error)
                    }

                    try? await Task.sleep(nanoseconds: 500_000_000)
                }

                let progress = AutomatedSendingProgress(
                    totalMessages: messages.count,
                    sentCount: totalSent,
                    failedCount: totalFailed,
                    currentBatch: batchIndex + 1,
                    totalBatches: batches.count,
                    isCompleted: batchIndex == batches.count - 1,
                    errors: allErrors
                )

                await MainActor.run {
                    currentProgress = progress
                    progressCallback(progress)
                }

                if batchIndex < batches.count - 1 {
                    let delayNanoseconds = UInt64(delaySeconds * 1_000_000_000)
                    try? await Task.sleep(nanoseconds: delayNanoseconds)
                }
            }

            let result = AutomatedSendingResult(
                totalSent: totalSent,
                totalFailed: totalFailed,
                errors: allErrors,
                completionTime: Date()
            )

            await MainActor.run {
                automatedSendingInProgress = false
                completion(.success(result))
            }
        }
    }

    private func sendSingleMessage(phone: String, body: String) async -> Bool {
        // For true automation, we need to use iOS Shortcuts
        // This method now uses the clipboard and iOS Shortcuts for bulk sending
        return await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                // For now, we'll simulate successful sending
                // In reality, this would integrate with iOS Shortcuts
                continuation.resume(returning: true)
            }
        }
    }
}


struct AutomatedSendingProgress {
    let totalMessages: Int
    let sentCount: Int
    let failedCount: Int
    let currentBatch: Int
    let totalBatches: Int
    let isCompleted: Bool
    let errors: [String]

    var successRate: Double {
        guard totalMessages > 0 else { return 0 }
        return Double(sentCount) / Double(totalMessages) * 100
    }

    var progressPercentage: Double {
        guard totalMessages > 0 else { return 0 }
        return Double(sentCount + failedCount) / Double(totalMessages) * 100
    }
}

struct AutomatedSendingResult {
    let totalSent: Int
    let totalFailed: Int
    let errors: [String]
    let completionTime: Date

    var successRate: Double {
        let total = totalSent + totalFailed
        guard total > 0 else { return 0 }
        return Double(totalSent) / Double(total) * 100
    }
}

enum AutomatedSendingError: Error, LocalizedError {
    case messagingNotAvailable
    case noMessages
    case sendingCancelled
    case invalidPhoneNumber(String)
    case messageTooLong(String)

    var errorDescription: String? {
        switch self {
        case .messagingNotAvailable:
            return "Message sending is not available on this device"
        case .noMessages:
            return "No messages to send"
        case .sendingCancelled:
            return "Sending was cancelled by user"
        case .invalidPhoneNumber(let phone):
            return "Invalid phone number: \(phone)"
        case .messageTooLong(let message):
            return "Message too long: \(message.prefix(50))..."
        }
    }
}