import SwiftUI

struct CampaignDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var campaignManager: CampaignManager
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var deliverySettings: DeliverySettings
    @EnvironmentObject var automatedMessagingService: AutomatedMessagingService

    let campaign: Campaign

    @State private var showingDeleteAlert = false
    @State private var showingSendAlert = false
    @State private var toastMessage: String? = nil

    var analytics: CampaignAnalytics {
        campaignManager.getCampaignAnalytics(campaign)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // Campaign Header
                    CampaignHeaderView(campaign: campaign, analytics: analytics)

                    // Progress Section
                    if campaign.status == "sending" || campaign.status == "completed" || campaign.status == "completed_with_errors" {
                        CampaignProgressSection(analytics: analytics)
                    }

                    // Template Section
                    if let template = campaign.template {
                        CampaignTemplateSection(template: template)
                    }

                    // Recipients Section
                    CampaignRecipientsSection(campaign: campaign)


                    // Actions Section
                    CampaignActionsSection(campaign: campaign) {
                        if campaign.status == "draft" {
                            showingSendAlert = true
                        }
                    } onSendViaShortcuts: {
                        sendViaShortcuts()
                    }
                }
                .padding()
            }
            .overlay(alignment: .top) {
                if let text = toastMessage {
                    ToastBanner(text: text)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.25), value: toastMessage)
                }
            }
            .navigationTitle("Campaign Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        if campaign.status == "draft" {
                            Button {
                                showingSendAlert = true
                            } label: {
                                Label("Send Campaign", systemImage: "paperplane")
                            }
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete Campaign", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Delete Campaign?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    campaignManager.deleteCampaign(campaign)
                    dismiss()
                }
            } message: {
                Text("This will permanently delete the campaign and all associated data. This action cannot be undone.")
            }
            .alert("Send Campaign?", isPresented: $showingSendAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Send") {
                    sendCampaign()
                }
            } message: {
                Text("This will send the campaign to \(analytics.totalRecipients) recipients. This action cannot be undone.")
            }
        }
    }

    private func sendCampaign() {
        campaignManager.sendCampaign(campaign) { result in
            switch result {
            case .success:
                print("Campaign sent successfully")
            case .failure(let error):
                print("Campaign failed: \(error)")
            }
        }
    }

    private func sendViaShortcuts() {
        print("🚀 === sendViaShortcuts() called ===")

        let messages = campaignManager.buildMessagesForShortcuts(campaign)
        let campaignId = campaign.objectID.uriRepresentation().absoluteString

        print("📊 Campaign details:")
        print("   - Name: \(campaign.name ?? "Unknown")")
        print("   - ID: \(campaignId)")
        print("   - Messages count: \(messages.count)")

        // Mark campaign as sending
        campaign.status = "sending"
        campaign.totalRecipients = Int32(messages.count)
        campaignManager.saveCampaign(campaign)
        print("✅ Campaign marked as sending")


        let result = ShortcutsService.sendMessagesViaShortcuts(messages: messages, campaignId: campaignId, shortcutName: deliverySettings.shortcutName, maxPerBatch: deliverySettings.shortcutsBatchSize)
        print("📤 Shortcuts result: copied \(result.copiedCount), remaining \(result.remainingCount)")

        if result.remainingCount > 0 {
            toast("Copied \(result.copiedCount) messages. \(result.remainingCount) remaining — reopen here to send next batch.")
        } else {
            toast("Copied \(result.copiedCount) messages to Shortcuts. Run the shortcut to send.")
        }

        print("🏁 === sendViaShortcuts() completed ===")
    }


    private func toast(_ text: String) {
        toastMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { toastMessage = nil }
        }
    }
}

struct CampaignHeaderView: View {
    let campaign: Campaign
    let analytics: CampaignAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(campaign.name ?? "Untitled Campaign")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Created \(analytics.dateCreated, style: .relative)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                CampaignStatusBadge(status: analytics.status)
            }

            if let scheduledDate = campaign.scheduledDate {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.orange)
                    Text("Scheduled for \(scheduledDate, style: .date) at \(scheduledDate, style: .time)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ToastBanner: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.black.opacity(0.85))
            .clipShape(Capsule())
            .padding(.top, 8)
    }
}

struct CampaignProgressSection: View {
    let analytics: CampaignAnalytics

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Progress")
                .font(.headline)
                .fontWeight(.semibold)

            HStack(spacing: 20) {
                ProgressStatView(
                    title: "Sent",
                    value: "\(analytics.sentCount)",
                    total: analytics.totalRecipients,
                    color: .green
                )

                ProgressStatView(
                    title: "Failed",
                    value: "\(analytics.failedCount)",
                    total: analytics.totalRecipients,
                    color: .red
                )

                ProgressStatView(
                    title: "Pending",
                    value: "\(analytics.pendingCount)",
                    total: analytics.totalRecipients,
                    color: .orange
                )
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Success Rate")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(String(format: "%.1f%%", analytics.successRate))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                ProgressView(value: Double(analytics.sentCount), total: Double(analytics.totalRecipients))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct ProgressStatView: View {
    let title: String
    let value: String
    let total: Int
    let color: Color

    var percentage: Double {
        guard total > 0, let intValue = Int(value) else { return 0 }
        return Double(intValue) / Double(total) * 100
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            VStack(spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(String(format: "%.1f%%", percentage))
                .font(.caption2)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

struct CampaignTemplateSection: View {
    let template: MessageTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Message Template")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Text(template.name ?? "Untitled Template")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(template.content ?? "")
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct CampaignRecipientsSection: View {
    let campaign: Campaign

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipients")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 8) {
                ForEach(campaign.targetGroupsArray, id: \.objectID) { group in
                    HStack {
                        Circle()
                            .fill(Color(hex: group.colorHex ?? "#007AFF"))
                            .frame(width: 12, height: 12)

                        Text(group.name ?? "Unknown Group")
                            .font(.subheadline)

                        Spacer()

                        Text("\(group.contactsArray.count) contacts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }

                Divider()

                HStack {
                    Text("Total Recipients")
                        .fontWeight(.medium)
                    Spacer()
                    Text("\(campaign.totalRecipients)")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct FollowUpsSection: View {
    let campaign: Campaign
    let sequences: [FollowUpSequence]
    @Binding var selectedSequence: FollowUpSequence?
    let onToggle: (Bool) -> Void
    let onManage: () -> Void

    @State private var isEnabled: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow-ups")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 8) {
                Toggle("Enable Follow-ups", isOn: $isEnabled)
                    .onChange(of: isEnabled) { _, newValue in onToggle(newValue) }

                if isEnabled {
                    Picker("Sequence", selection: $selectedSequence) {
                        Text("Choose a sequence").tag(nil as FollowUpSequence?)
                        ForEach(sequences, id: \.objectID) { seq in
                            Text(seq.name ?? "Untitled").tag(seq as FollowUpSequence?)
                        }
                    }
                    .onChange(of: selectedSequence) { _, _ in onToggle(isEnabled) }

                    Button(action: onManage) {
                        Label("Manage Sequences", systemImage: "slider.horizontal.3")
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .onAppear {
            isEnabled = campaign.isFollowUpEnabled
            selectedSequence = campaign.followUpSequence
        }
    }
}

struct CampaignActionsSection: View {
    let campaign: Campaign
    let onSend: () -> Void
    let onSendViaShortcuts: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if campaign.status == "draft" {
                // Primary Manual Sending
                Button {
                    onSend()
                } label: {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send Campaign")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Shortcuts Support Section
                VStack(spacing: 8) {
                    Button {
                        onSendViaShortcuts()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up.on.square")
                            Text("Send via Shortcuts")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // Shortcut Download Link
                    Button {
                        if let url = URL(string: "https://www.icloud.com/shortcuts/5f30c7cc985a4b5eb1bf6fcf06b01f01") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Get BulkMess Shortcut")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
            } else if campaign.status == "sending" {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text("Campaign is currently sending...")
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            } else if campaign.status == "completed" {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Campaign completed successfully")
                        .foregroundColor(.green)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            } else if campaign.status == "completed_with_errors" {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Campaign completed with errors")
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.template(ctx, name: "Notice", content: "Hi {{firstName}}")
        let contacts = (1...2).map { i in
            PreviewSeed.contact(ctx, firstName: "P\(i)", lastName: "Smith", phone: "+1555333\(i)")
        }
        _ = PreviewSeed.group(ctx, name: "Group A", colorHex: "#FF9F0A", contacts: contacts)
        // templates and groups will be visible after managers initialize
    }
    // Create campaign via manager
    let t = env.templateManager.templates.first!
    let g = env.contactManager.contactGroups.first!
    let campaign = env.campaignManager.createCampaign(name: "Sample", template: t, targetGroups: [g])
    return CampaignDetailView(campaign: campaign)
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.campaignManager)
}
