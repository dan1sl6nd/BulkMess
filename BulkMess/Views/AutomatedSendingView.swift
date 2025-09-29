import SwiftUI

struct AutomatedSendingView: View {
    let campaign: Campaign
    let messages: [(phone: String, body: String)]
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bulkAutomatedMessagingService = BulkAutomatedMessagingService()
    @State private var selectedMethod: SendingMethod = .autoSend
    @State private var batchSize = 10
    @State private var delaySeconds = 2.0
    @State private var showingConfirmation = false
    @State private var showingProgress = false
    @State private var currentProgress: AutomatedSendingProgress?
    @State private var sendingResult: AutomatedSendingResult?
    @State private var showingResult = false
    @State private var showingSetupInstructions = false

    enum SendingMethod: String, CaseIterable {
        case autoSend = "Auto Send"
        case batchProcessor = "Batch Processor"

        var description: String {
            switch self {
            case .autoSend:
                return "Send all messages automatically with 1-second delays. Best for up to 100 messages."
            case .batchProcessor:
                return "Advanced batch processing with configurable delays and error handling. Best for large campaigns."
            }
        }

        var icon: String {
            switch self {
            case .autoSend: return "bolt.fill"
            case .batchProcessor: return "gearshape.2.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            List {
                // Campaign Info
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(campaign.name ?? "Campaign")
                            .font(.headline)
                        Text("\(messages.count) messages ready to send")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                // Sending Method Selection
                Section("Sending Method") {
                    ForEach(SendingMethod.allCases, id: \.self) { method in
                        SendingMethodRow(
                            method: method,
                            isSelected: selectedMethod == method,
                            onSelect: { selectedMethod = method }
                        )
                    }
                }

                // Configuration
                if selectedMethod == .batchProcessor {
                    Section("Batch Settings") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Batch Size")
                                Spacer()
                                Text("\(batchSize) messages")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: .init(
                                get: { Double(batchSize) },
                                set: { batchSize = Int($0) }
                            ), in: 5...20, step: 1)

                            HStack {
                                Text("Delay Between Batches")
                                Spacer()
                                Text("\(delaySeconds, specifier: "%.1f") seconds")
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $delaySeconds, in: 1...10, step: 0.5)
                        }
                        .padding(.vertical, 4)
                    }
                }

                // Performance Info
                Section("Estimated Performance") {
                    VStack(alignment: .leading, spacing: 8) {
                        if selectedMethod == .autoSend {
                            PerformanceRow(
                                title: "Total Time",
                                value: "\(messages.count) seconds",
                                icon: "clock"
                            )
                            PerformanceRow(
                                title: "Method",
                                value: "Continuous sending",
                                icon: "arrow.right"
                            )
                        } else {
                            let batches = Int(ceil(Double(messages.count) / Double(batchSize)))
                            let totalTime = Double(batches) * delaySeconds + Double(messages.count) * 0.5

                            PerformanceRow(
                                title: "Batches",
                                value: "\(batches) batches",
                                icon: "square.grid.3x3"
                            )
                            PerformanceRow(
                                title: "Total Time",
                                value: "\(Int(totalTime)) seconds",
                                icon: "clock"
                            )
                        }
                    }
                }

                // Setup Instructions
                Section("Shortcut Setup") {
                    Button {
                        showingSetupInstructions = true
                    } label: {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Setup Instructions")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Learn how to create the required iOS Shortcut")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(.plain)
                }

                // Send Button
                Section {
                    Button {
                        showingConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: selectedMethod.icon)
                            Text("Send via \(selectedMethod.rawValue)")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(bulkAutomatedMessagingService.automatedSendingInProgress)
                }
            }
            .navigationTitle("Automated Sending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Send \(messages.count) Messages",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Send via \(selectedMethod.rawValue)") {
                    sendMessages()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will copy message data to clipboard and run an iOS Shortcut for automated bulk sending. Make sure you have the required shortcut installed.")
            }
            .sheet(isPresented: $showingProgress) {
                AutomatedSendingProgressView(
                    progress: currentProgress,
                    onCancel: {
                        showingProgress = false
                    }
                )
            }
            .sheet(isPresented: $showingResult) {
                AutomatedSendingResultView(
                    result: sendingResult,
                    onDismiss: {
                        showingResult = false
                        dismiss()
                    }
                )
            }
            .sheet(isPresented: $showingSetupInstructions) {
                ShortcutSetupInstructionsView(method: selectedMethod)
            }
        }
    }

    private func sendMessages() {
        showingProgress = true

        let method: AutomatedSendingMethod = selectedMethod == .autoSend ?
            .autoSend :
            .batchProcessor(batchSize: batchSize, delaySeconds: delaySeconds)

        bulkAutomatedMessagingService.sendMessagesAutomatically(
            messages: messages,
            method: method,
            progressCallback: { progress in
                currentProgress = progress
            },
            completion: { result in
                showingProgress = false
                switch result {
                case .success(let sendingResult):
                    self.sendingResult = sendingResult
                    showingResult = true
                case .failure(let error):
                    print("Automated sending failed: \(error)")
                    // Could show error alert here
                }
            }
        )
    }
}

// MARK: - Supporting Views

struct SendingMethodRow: View {
    let method: AutomatedSendingView.SendingMethod
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: method.icon)
                    .foregroundColor(isSelected ? .blue : .secondary)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(method.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(method.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

struct PerformanceRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(title)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    let env = PreviewEnvironment.make()
    let sampleCampaign = Campaign(context: env.ctx)
    sampleCampaign.name = "Test Campaign"

    let sampleMessages = [
        (phone: "+1234567890", body: "Hello John!"),
        (phone: "+0987654321", body: "Hello Jane!"),
        (phone: "+1122334455", body: "Hello Bob!")
    ]

    return AutomatedSendingView(campaign: sampleCampaign, messages: sampleMessages)
}