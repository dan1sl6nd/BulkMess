import Foundation
import MessageUI
import UIKit

class MessagingService: NSObject, ObservableObject {
    @Published var isMessageComposerPresented = false
    @Published var canSendMessages = false

    private var messageComposeDelegate: MessageComposeDelegate?

    override init() {
        super.init()
        checkMessageAvailability()
    }

    // MARK: - Message Availability

    func checkMessageAvailability() {
        canSendMessages = MFMessageComposeViewController.canSendText()
    }

    // MARK: - Single Message Sending

    func sendSingleMessage(
        to phoneNumber: String,
        content: String,
        completion: @escaping (Result<Void, MessagingError>) -> Void
    ) {
        guard canSendMessages else {
            completion(.failure(.messageNotSupported))
            return
        }

        guard let presenter = Self.topViewController() else {
            completion(.failure(.noViewController))
            return
        }

        let messageController = MFMessageComposeViewController()
        messageController.recipients = [phoneNumber]
        messageController.body = content

        messageComposeDelegate = MessageComposeDelegate { result in
            switch result {
            case .sent:
                completion(.success(()))
            case .cancelled:
                completion(.failure(.cancelled))
            case .failed:
                completion(.failure(.sendFailed))
            @unknown default:
                completion(.failure(.unknown))
            }
        }

        messageController.messageComposeDelegate = messageComposeDelegate

        DispatchQueue.main.async {
            presenter.present(messageController, animated: true)
        }
    }

    // MARK: - Bulk Message Sending

    func sendBulkMessages(
        messages: [(phoneNumber: String, content: String)],
        batchSize: Int = 10,
        delayBetweenBatches: TimeInterval = 2.0,
        progressCallback: @escaping (Int, Int) -> Void,
        completion: @escaping (Result<BulkMessageResult, MessagingError>) -> Void,
        forceSimulate: Bool = false
    ) {
        #if targetEnvironment(simulator)
        // Simulator: simulate bulk sending
        simulateBulk(messages: messages,
                     batchSize: batchSize,
                     delayBetweenBatches: delayBetweenBatches,
                     progressCallback: progressCallback,
                     completion: completion)
        #else
        if forceSimulate {
            simulateBulk(messages: messages,
                         batchSize: batchSize,
                         delayBetweenBatches: delayBetweenBatches,
                         progressCallback: progressCallback,
                         completion: completion)
        } else {
            // Real device: if Messages is available, present composer sequentially for each message
            guard canSendMessages else {
                completion(.failure(.messageNotSupported))
                return
            }
            sendBulkMessagesViaComposer(
                messages: messages,
                progressCallback: progressCallback,
                completion: completion
            )
        }
        #endif
    }

    // MARK: - Real-device interactive bulk via Messages composer (sequential)

    private func sendBulkMessagesViaComposer(
        messages: [MessageData],
        progressCallback: @escaping (Int, Int) -> Void,
        completion: @escaping (Result<BulkMessageResult, MessagingError>) -> Void
    ) {
        let total = messages.count
        var sent = 0
        var failed = 0

        func sendNext(index: Int) {
            if index >= total {
                let result = BulkMessageResult(totalSent: sent, totalFailed: failed, totalMessages: total)
                completion(.success(result))
                return
            }

            let msg = messages[index]

            sendSingleMessage(to: msg.phoneNumber, content: msg.content) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        sent += 1
                    case .failure:
                        failed += 1
                    }
                    progressCallback(sent, total)
                    // Small delay to avoid aggressively re-presenting UI
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        sendNext(index: index + 1)
                    }
                }
            }
        }

        sendNext(index: 0)
    }

    // MARK: - Simulator bulk simulation helper

    private func simulateBulk(
        messages: [MessageData],
        batchSize: Int,
        delayBetweenBatches: TimeInterval,
        progressCallback: @escaping (Int, Int) -> Void,
        completion: @escaping (Result<BulkMessageResult, MessagingError>) -> Void
    ) {
        let totalCount = messages.count
        let batches = messages.chunked(into: batchSize)
        processBatch(
            batches: batches,
            currentBatchIndex: 0,
            currentSentCount: 0,
            currentFailedCount: 0,
            totalCount: totalCount,
            delayBetweenBatches: delayBetweenBatches,
            progressCallback: progressCallback,
            completion: completion
        )
    }

    private func processBatch(
        batches: [[MessageData]],
        currentBatchIndex: Int,
        currentSentCount: Int,
        currentFailedCount: Int,
        totalCount: Int,
        delayBetweenBatches: TimeInterval,
        progressCallback: @escaping (Int, Int) -> Void,
        completion: @escaping (Result<BulkMessageResult, MessagingError>) -> Void
    ) {
        guard currentBatchIndex < batches.count else {
            // All batches processed
            let result = BulkMessageResult(
                totalSent: currentSentCount,
                totalFailed: currentFailedCount,
                totalMessages: totalCount
            )
            completion(.success(result))
            return
        }

        let batch = batches[currentBatchIndex]
        let group = DispatchGroup()
        var batchSentCount = 0
        var batchFailedCount = 0

        for message in batch {
            group.enter()

            // In a real implementation, you would integrate with an SMS service provider
            // For now, we'll simulate the sending process
            simulateSendMessage(
                phoneNumber: message.phoneNumber,
                content: message.content
            ) { result in
                defer { group.leave() }

                switch result {
                case .success:
                    batchSentCount += 1
                case .failure:
                    batchFailedCount += 1
                }
            }
        }

        group.notify(queue: .main) {
            let newSentCount = currentSentCount + batchSentCount
            let newFailedCount = currentFailedCount + batchFailedCount
            // Report the number of successfully sent messages so far
            progressCallback(newSentCount, totalCount)

            // Add delay before processing next batch
            DispatchQueue.main.asyncAfter(deadline: .now() + delayBetweenBatches) {
                self.processBatch(
                    batches: batches,
                    currentBatchIndex: currentBatchIndex + 1,
                    currentSentCount: newSentCount,
                    currentFailedCount: newFailedCount,
                    totalCount: totalCount,
                    delayBetweenBatches: delayBetweenBatches,
                    progressCallback: progressCallback,
                    completion: completion
                )
            }
        }
    }

    // MARK: - Message Simulation (Replace with real SMS service)

    private func simulateSendMessage(
        phoneNumber: String,
        content: String,
        completion: @escaping (Result<Void, MessagingError>) -> Void
    ) {
        // Simulate network delay
        DispatchQueue.global().asyncAfter(deadline: .now() + Double.random(in: 0.1...0.5)) {
            // Simulate 95% success rate
            let success = Double.random(in: 0...1) > 0.05

            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(.sendFailed))
                }
            }
        }
    }

    // MARK: - Message Composition UI

    func presentMessageComposer(
        phoneNumbers: [String],
        messageBody: String,
        completion: @escaping (MessageComposeResult) -> Void
    ) {
        guard canSendMessages else {
            completion(.failed)
            return
        }

        guard let presenter = Self.topViewController() else {
            completion(.failed)
            return
        }

        let messageController = MFMessageComposeViewController()
        messageController.recipients = phoneNumbers
        messageController.body = messageBody

        messageComposeDelegate = MessageComposeDelegate(completion: completion)
        messageController.messageComposeDelegate = messageComposeDelegate

        DispatchQueue.main.async {
            presenter.present(messageController, animated: true)
        }
    }
}

// MARK: - Supporting Types

extension MessagingService {
    typealias MessageData = (phoneNumber: String, content: String)
}

struct BulkMessageResult {
    let totalSent: Int
    let totalFailed: Int
    let totalMessages: Int

    var successRate: Double {
        guard totalMessages > 0 else { return 0 }
        return Double(totalSent) / Double(totalMessages) * 100
    }
}

enum MessagingError: Error, LocalizedError {
    case messageNotSupported
    case noViewController
    case cancelled
    case sendFailed
    case unknown

    var errorDescription: String? {
        switch self {
        case .messageNotSupported:
            return "SMS messaging is not supported on this device"
        case .noViewController:
            return "Unable to present message composer"
        case .cancelled:
            return "Message sending was cancelled"
        case .sendFailed:
            return "Failed to send message"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

class MessageComposeDelegate: NSObject, MFMessageComposeViewControllerDelegate {
    private let completion: (MessageComposeResult) -> Void

    init(completion: @escaping (MessageComposeResult) -> Void) {
        self.completion = completion
        super.init()
    }

    func messageComposeViewController(
        _ controller: MFMessageComposeViewController,
        didFinishWith result: MessageComposeResult
    ) {
        controller.dismiss(animated: true) {
            self.completion(result)
        }
    }
}

// MARK: - View Controller presentation helpers

extension MessagingService {
    private static func topViewController(
        base: UIViewController? = keyWindow()?.rootViewController
    ) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }

    private static func keyWindow() -> UIWindow? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}
