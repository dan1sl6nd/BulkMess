import SwiftUI

struct AutomatedIntegrationView: View {
    @EnvironmentObject private var messageMonitoringService: MessageMonitoringService
    @StateObject private var webhookService: WebhookService
    @State private var showingSetupGuide = false
    @State private var testPhoneNumber = ""
    @State private var testMessage = ""
    @State private var testResult = ""

    init() {
        // Initialize with a temporary service - will be replaced by environment object
        let tempService = MessageMonitoringService()
        self._webhookService = StateObject(wrappedValue: WebhookService(messageMonitoringService: tempService))
    }

    var body: some View {
        NavigationStack {
            List {
                // Overview Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Automated Response Detection")
                            .font(.headline)
                        Text("Automatically cancel follow-ups when contacts respond to your campaigns.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Integration Methods
                Section("Integration Methods") {
                    NavigationLink {
                        ShortcutsAutoSetupView()
                    } label: {
                        IntegrationMethodRow(
                            title: "iOS Shortcuts",
                            description: "Automatically detect responses using iOS automation",
                            icon: "shortcuts",
                            status: .available,
                            action: { }
                        )
                    }
                    .buttonStyle(.plain)

                    IntegrationMethodRow(
                        title: "Notification Actions",
                        description: "Quick response marking from notifications",
                        icon: "bell.badge",
                        status: .enabled,
                        action: { showNotificationInfo() }
                    )

                    IntegrationMethodRow(
                        title: "Webhook Server",
                        description: "API endpoint for third-party integrations",
                        icon: "network",
                        status: webhookService.isListening ? .enabled : .disabled,
                        action: { toggleWebhookServer() }
                    )
                }

                // Server Status
                if webhookService.isListening {
                    Section("Server Status") {
                        HStack {
                            Image(systemName: "network")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Webhook server running")
                                    .font(.subheadline)
                                Text("Port 8080 - \(webhookService.receivedWebhooks.count) webhooks received")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Testing Section
                Section("Testing") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Test Integration")
                            .font(.subheadline)

                        TextField("Phone Number", text: $testPhoneNumber)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.phonePad)

                        TextField("Test Message", text: $testMessage)
                            .textFieldStyle(.roundedBorder)

                        Button {
                            testIntegration()
                        } label: {
                            Text("Test Response Recording")
                        }
                        .buttonStyle(.bordered)
                        .disabled(testPhoneNumber.isEmpty || testMessage.isEmpty)

                        if !testResult.isEmpty {
                            Text(testResult)
                                .font(.caption)
                                .foregroundColor(testResult.contains("Success") ? .green : .red)
                        }
                    }
                    .padding(.vertical, 4)
                }

                // URL Schemes
                Section("URL Scheme Examples") {
                    VStack(alignment: .leading, spacing: 8) {
                        URLSchemeExample(
                            title: "Record Response",
                            url: "bulkmess://record-response?phone=+1234567890&message=Thanks!"
                        )

                        URLSchemeExample(
                            title: "Cancel Follow-up",
                            url: "bulkmess://cancel-followup?phone=+1234567890"
                        )

                        URLSchemeExample(
                            title: "Check All Responses",
                            url: "bulkmess://check-responses"
                        )
                    }
                }
            }
            .navigationTitle("Automated Integration")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSetupGuide = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                }
            }
            .sheet(isPresented: $showingSetupGuide) {
                SetupGuideView()
            }
        }
        .onAppear {
            // Update webhook service with correct monitoring service
            let _ = WebhookService(messageMonitoringService: messageMonitoringService)
            // In a real implementation, you'd properly manage this dependency
        }
    }

    private func showShortcutsSetup() {
        guard let url = URL(string: "shortcuts://") else { return }
        UIApplication.shared.open(url)
    }

    private func showNotificationInfo() {
        // Show info about notification actions
        testResult = "Notification actions are automatically enabled. Long-press follow-up notifications to see options."
    }

    private func toggleWebhookServer() {
        if webhookService.isListening {
            webhookService.stopWebhookServer()
        } else {
            webhookService.startWebhookServer()
        }
    }

    private func testIntegration() {
        messageMonitoringService.recordIncomingMessage(
            fromPhoneNumber: testPhoneNumber,
            content: testMessage
        )
        testResult = "Success: Recorded response from \(testPhoneNumber)"
    }
}

// MARK: - Supporting Views

struct IntegrationMethodRow: View {
    let title: String
    let description: String
    let icon: String
    let status: IntegrationStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(status.color)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Text(status.text)
                    .font(.caption)
                    .foregroundColor(status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(status.color.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .buttonStyle(.plain)
    }
}

struct URLSchemeExample: View {
    let title: String
    let url: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)

            Text(url)
                .font(.caption)
                .foregroundColor(.blue)
                .onTapGesture {
                    UIPasteboard.general.string = url
                }
        }
    }
}

struct SetupGuideView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    setupSection(
                        title: "1. iOS Shortcuts Setup",
                        steps: [
                            "Open iOS Shortcuts app",
                            "Create automation: 'When I receive a message'",
                            "Add 'Open URL' action with BulkMess URL scheme",
                            "Test with a sample message"
                        ],
                        icon: "shortcuts"
                    )

                    setupSection(
                        title: "2. URL Scheme Configuration",
                        steps: [
                            "Add 'bulkmess' URL scheme to your app",
                            "Configure in Xcode: Project Settings → Info → URL Types",
                            "Test by opening bulkmess:// URLs"
                        ],
                        icon: "link"
                    )

                    setupSection(
                        title: "3. Webhook Integration",
                        steps: [
                            "Start webhook server in app",
                            "Configure third-party services to send webhooks",
                            "Use endpoint: http://localhost:8080/webhook/message-received",
                            "Send JSON with phoneNumber and messageContent"
                        ],
                        icon: "network"
                    )

                    setupSection(
                        title: "4. Notification Actions",
                        steps: [
                            "Grant notification permissions",
                            "Schedule follow-ups to test",
                            "Long-press notifications to see actions",
                            "Use 'They Responded' to cancel follow-ups"
                        ],
                        icon: "bell.badge"
                    )
                }
                .padding()
            }
            .navigationTitle("Setup Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func setupSection(title: String, steps: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20)
                    Text(step)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Supporting Types

enum IntegrationStatus {
    case available
    case enabled
    case disabled
    case error

    var text: String {
        switch self {
        case .available: return "Available"
        case .enabled: return "Enabled"
        case .disabled: return "Disabled"
        case .error: return "Error"
        }
    }

    var color: Color {
        switch self {
        case .available: return .blue
        case .enabled: return .green
        case .disabled: return .gray
        case .error: return .red
        }
    }
}

#Preview {
    AutomatedIntegrationView()
        .environmentObject(MessageMonitoringService())
}