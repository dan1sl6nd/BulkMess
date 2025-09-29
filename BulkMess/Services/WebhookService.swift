import Foundation
import Network

/// Simple webhook service for receiving message response notifications from external services
class WebhookService: ObservableObject {
    private let messageMonitoringService: MessageMonitoringService
    private var listener: NWListener?
    private let port: NWEndpoint.Port = 8080

    @Published var isListening = false
    @Published var receivedWebhooks: [WebhookEvent] = []

    init(messageMonitoringService: MessageMonitoringService) {
        self.messageMonitoringService = messageMonitoringService
    }

    // MARK: - Webhook Server

    func startWebhookServer() {
        do {
            listener = try NWListener(using: .tcp, on: port)
            listener?.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection)
            }

            listener?.start(queue: .global())
            DispatchQueue.main.async {
                self.isListening = true
                print("Webhook server started on port \(self.port)")
            }
        } catch {
            print("Failed to start webhook server: \(error)")
        }
    }

    func stopWebhookServer() {
        listener?.cancel()
        listener = nil
        DispatchQueue.main.async {
            self.isListening = false
            print("Webhook server stopped")
        }
    }

    private func handleNewConnection(_ connection: NWConnection) {
        connection.start(queue: .global())

        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                self?.processWebhookData(data)
            }

            // Send a simple HTTP response
            let response = """
                HTTP/1.1 200 OK
                Content-Type: application/json
                Content-Length: 25

                {"status": "received"}
                """.data(using: .utf8)!

            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func processWebhookData(_ data: Data) {
        guard let requestString = String(data: data, encoding: .utf8) else { return }

        // Parse HTTP request to extract JSON body
        let lines = requestString.components(separatedBy: "\r\n")
        guard let jsonStartIndex = lines.firstIndex(where: { $0.isEmpty }) else { return }

        let jsonBodyLines = Array(lines.dropFirst(jsonStartIndex + 1))
        let jsonBody = jsonBodyLines.joined(separator: "\r\n")

        guard let jsonData = jsonBody.data(using: .utf8) else { return }

        processWebhookJSON(jsonData)
    }

    private func processWebhookJSON(_ data: Data) {
        do {
            let webhook = try JSONDecoder().decode(WebhookEvent.self, from: data)

            DispatchQueue.main.async {
                self.receivedWebhooks.append(webhook)
                self.handleWebhookEvent(webhook)
            }
        } catch {
            print("Failed to parse webhook JSON: \(error)")
        }
    }

    private func handleWebhookEvent(_ event: WebhookEvent) {
        switch event.type {
        case .messageReceived:
            if let phoneNumber = event.phoneNumber,
               let messageContent = event.messageContent {
                messageMonitoringService.recordIncomingMessage(
                    fromPhoneNumber: phoneNumber,
                    content: messageContent,
                    receivedAt: event.timestamp ?? Date()
                )
                print("Recorded message response via webhook from \(phoneNumber)")
            }

        case .followupCancel:
            if let phoneNumber = event.phoneNumber {
                messageMonitoringService.recordIncomingMessage(
                    fromPhoneNumber: phoneNumber,
                    content: "Follow-up cancelled via webhook",
                    receivedAt: event.timestamp ?? Date()
                )
                print("Cancelled follow-ups via webhook for \(phoneNumber)")
            }

        case .bulkCheck:
            messageMonitoringService.checkAllActiveCampaigns()
            print("Triggered bulk response check via webhook")
        }
    }

    // MARK: - REST API Endpoints

    /// Generate a simple REST API interface using URLSession for external integrations
    static func setupRESTAPI() {
        // This would typically be handled by a proper web framework
        // For demonstration, we'll show the expected API structure
        print("REST API endpoints available:")
        print("POST /webhook/message-received - Record a received message")
        print("POST /webhook/cancel-followup - Cancel follow-ups for a contact")
        print("POST /webhook/check-responses - Trigger response check for all campaigns")
    }

    /// Handle REST API calls (simplified implementation)
    func handleRESTAPICall(endpoint: String, data: Data) -> APIResponse {
        switch endpoint {
        case "/webhook/message-received":
            return handleMessageReceivedAPI(data: data)
        case "/webhook/cancel-followup":
            return handleCancelFollowupAPI(data: data)
        case "/webhook/check-responses":
            return handleCheckResponsesAPI()
        default:
            return APIResponse(success: false, message: "Unknown endpoint")
        }
    }

    private func handleMessageReceivedAPI(data: Data) -> APIResponse {
        do {
            let request = try JSONDecoder().decode(MessageReceivedRequest.self, from: data)
            messageMonitoringService.recordIncomingMessage(
                fromPhoneNumber: request.phoneNumber,
                content: request.messageContent,
                receivedAt: request.timestamp ?? Date()
            )
            return APIResponse(success: true, message: "Message recorded successfully")
        } catch {
            return APIResponse(success: false, message: "Invalid request format: \(error)")
        }
    }

    private func handleCancelFollowupAPI(data: Data) -> APIResponse {
        do {
            let request = try JSONDecoder().decode(CancelFollowupRequest.self, from: data)
            messageMonitoringService.recordIncomingMessage(
                fromPhoneNumber: request.phoneNumber,
                content: "Follow-up cancelled via API",
                receivedAt: Date()
            )
            return APIResponse(success: true, message: "Follow-up cancelled successfully")
        } catch {
            return APIResponse(success: false, message: "Invalid request format: \(error)")
        }
    }

    private func handleCheckResponsesAPI() -> APIResponse {
        messageMonitoringService.checkAllActiveCampaigns()
        return APIResponse(success: true, message: "Response check triggered successfully")
    }
}

// MARK: - Supporting Types

struct WebhookEvent: Codable {
    let type: WebhookEventType
    let phoneNumber: String?
    let messageContent: String?
    let timestamp: Date?
    let campaignId: String?
}

enum WebhookEventType: String, Codable {
    case messageReceived = "message_received"
    case followupCancel = "followup_cancel"
    case bulkCheck = "bulk_check"
}

struct MessageReceivedRequest: Codable {
    let phoneNumber: String
    let messageContent: String
    let timestamp: Date?
}

struct CancelFollowupRequest: Codable {
    let phoneNumber: String
}

struct APIResponse: Codable {
    let success: Bool
    let message: String
}

// MARK: - Integration Examples

extension WebhookService {

    /// Example webhook payload for message received
    static var exampleMessageReceivedPayload: String {
        """
        {
            "type": "message_received",
            "phoneNumber": "+1234567890",
            "messageContent": "Thanks for the message!",
            "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """
    }

    /// Example webhook payload for cancel follow-up
    static var exampleCancelFollowupPayload: String {
        """
        {
            "type": "followup_cancel",
            "phoneNumber": "+1234567890",
            "timestamp": "\(ISO8601DateFormatter().string(from: Date()))"
        }
        """
    }

    /// Example curl commands for testing
    static var exampleCurlCommands: [String] {
        [
            """
            # Record a received message
            curl -X POST http://localhost:8080/webhook/message-received \\
                -H "Content-Type: application/json" \\
                -d '{"phoneNumber": "+1234567890", "messageContent": "Thanks!"}'
            """,
            """
            # Cancel follow-ups for a contact
            curl -X POST http://localhost:8080/webhook/cancel-followup \\
                -H "Content-Type: application/json" \\
                -d '{"phoneNumber": "+1234567890"}'
            """,
            """
            # Trigger response check
            curl -X POST http://localhost:8080/webhook/check-responses \\
                -H "Content-Type: application/json" \\
                -d '{}'
            """
        ]
    }
}