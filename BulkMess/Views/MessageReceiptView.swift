import SwiftUI

struct MessageReceiptView: View {
    let contact: Contact
    @State private var isRecordingReceipt = false
    @State private var showReceiptAlert = false
    @State private var messageContent = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Activity")
                .font(.headline)

            // Show recent received messages
            if !receivedMessages.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent Responses:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    ForEach(receivedMessages.prefix(3), id: \.objectID) { message in
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text(message.content ?? "No content")
                                    .font(.caption)
                                if let date = message.dateReceived {
                                    Text(date.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }

            // Button to record new receipt
            Button {
                showReceiptAlert = true
            } label: {
                Label("Mark as Responded", systemImage: "checkmark.message")
            }
            .buttonStyle(.bordered)
            .disabled(isRecordingReceipt)
        }
        .alert("Record Message Receipt", isPresented: $showReceiptAlert) {
            TextField("Message content (optional)", text: $messageContent)
            Button("Record") {
                recordReceipt()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Mark this contact as having responded to cancel any pending follow-ups.")
        }
    }

    private var receivedMessages: [Message] {
        let messages = contact.messagesArray.filter { $0.isIncoming }
        return messages.sorted {
            ($0.dateReceived ?? .distantPast) > ($1.dateReceived ?? .distantPast)
        }
    }

    private func recordReceipt() {
        isRecordingReceipt = true

        print("📥 Recording message from \(contact.firstName ?? "Unknown"): \(messageContent.isEmpty ? "Response recorded manually" : messageContent)")

        messageContent = ""
        isRecordingReceipt = false
    }
}

// MARK: - Campaign Receipt Tracking

struct CampaignReceiptView: View {
    let campaign: Campaign
    @State private var responseRate: Double = 0.0
    @State private var showMonitoringSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Response Tracking")
                    .font(.headline)
                Spacer()
                Button {
                    checkForResponses()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Response Rate: \(responseRate, specifier: "%.1f")%")
                    .font(.subheadline)

                ProgressView(value: responseRate, total: 100)
                    .progressViewStyle(.linear)

                Button {
                    showMonitoringSheet = true
                } label: {
                    Label("Manage Responses", systemImage: "list.bullet.rectangle")
                }
                .buttonStyle(.bordered)
            }
        }
        .onAppear {
            calculateResponseRate()
        }
        .sheet(isPresented: $showMonitoringSheet) {
            CampaignResponseManagementView(campaign: campaign)
        }
    }

    private func calculateResponseRate() {
        // Create a temporary monitoring service to calculate rate
        let monitoringService = MessageMonitoringService()
        responseRate = monitoringService.getResponseRate(for: campaign)
    }

    private func checkForResponses() {
        let monitoringService = MessageMonitoringService()
        monitoringService.checkAndCancelFollowUps(for: campaign)
        calculateResponseRate()
    }
}

// MARK: - Campaign Response Management

struct CampaignResponseManagementView: View {
    @Environment(\.dismiss) private var dismiss
    let campaign: Campaign
    @State private var respondedContacts: [Contact] = []

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(allContacts, id: \.objectID) { contact in
                        ContactResponseRow(
                            contact: contact,
                            hasResponded: respondedContacts.contains(contact),
                            onToggleResponse: { hasResponded in
                                if hasResponded {
                                    recordResponse(for: contact)
                                } else {
                                    removeResponse(for: contact)
                                }
                            }
                        )
                    }
                } header: {
                    Text("Campaign Recipients")
                } footer: {
                    Text("Toggle responses to cancel or restore follow-ups for specific contacts.")
                }
            }
            .navigationTitle("Response Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadRespondedContacts()
            }
        }
    }

    private var allContacts: [Contact] {
        let contacts = Set(campaign.targetGroupsArray.flatMap { $0.contactsArray })
        return Array(contacts).sorted {
            contactName($0) < contactName($1)
        }
    }

    private func contactName(_ contact: Contact) -> String {
        let first = contact.firstName ?? ""
        let last = contact.lastName ?? ""
        if !first.isEmpty || !last.isEmpty {
            return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        }
        return contact.phoneNumber ?? "Unknown"
    }

    private func loadRespondedContacts() {
        let campaignDate = campaign.scheduledDate ?? campaign.dateCreated ?? Date()
        let monitoringService = MessageMonitoringService()
        respondedContacts = monitoringService.getRespondedContacts(since: campaignDate)
    }

    private func recordResponse(for contact: Contact) {
        print("📥 Recording message from \(contact.firstName ?? "Unknown"): Response recorded via management interface")
        loadRespondedContacts()
    }

    private func removeResponse(for contact: Contact) {
        // Remove incoming messages for this contact
        // This is a simplified implementation
        respondedContacts.removeAll { $0.objectID == contact.objectID }
    }
}

// MARK: - Contact Response Row

struct ContactResponseRow: View {
    let contact: Contact
    let hasResponded: Bool
    let onToggleResponse: (Bool) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(contactName)
                    .font(.headline)
                Text(contact.phoneNumber ?? "No phone")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Toggle("", isOn: .init(
                get: { hasResponded },
                set: { newValue in
                    onToggleResponse(newValue)
                }
            ))
            .labelsHidden()
        }
    }

    private var contactName: String {
        let first = contact.firstName ?? ""
        let last = contact.lastName ?? ""
        if !first.isEmpty || !last.isEmpty {
            return "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        }
        return "Unknown Contact"
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        PreviewSeed.contact(ctx, firstName: "John", lastName: "Doe", phone: "+1234567890")
    }

    MessageReceiptView(contact: env.ctx.registeredObjects.first { $0 is Contact } as! Contact)
}