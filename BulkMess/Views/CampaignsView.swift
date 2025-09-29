import SwiftUI

struct CampaignsView: View {
    @EnvironmentObject var campaignManager: CampaignManager
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var showingCreateCampaign = false
    @State private var selectedCampaign: Campaign?

    var activeCampaigns: [Campaign] {
        campaignManager.getActiveCampaigns()
    }

    var canCreateCampaign: Bool {
        // Allow campaign creation even if templates are empty; only require contacts
        !contactManager.contacts.isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if campaignManager.campaigns.isEmpty {
                    EmptyStateCard(
                        icon: "megaphone.fill",
                        title: "No Campaigns Yet",
                        message: "Create your first campaign to send bulk messages to multiple contacts at once",
                        buttonTitle: canCreateCampaign ? "Create Campaign" : nil,
                        buttonAction: canCreateCampaign ? { showingCreateCampaign = true } : nil,
                        accentColor: AppTheme.accent
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.lg) {
                            if !activeCampaigns.isEmpty {
                                SectionCard(title: "Active Campaigns", subtitle: "Currently running campaigns") {
                                    LazyVStack(spacing: AppTheme.Spacing.md) {
                                        ForEach(activeCampaigns, id: \.objectID) { campaign in
                                            ModernCampaignCard(campaign: campaign, isActive: true) {
                                                selectedCampaign = campaign
                                            }
                                        }
                                    }
                                }
                            }

                            SectionCard(title: "All Campaigns", subtitle: "\(campaignManager.campaigns.count) campaigns total") {
                                LazyVStack(spacing: AppTheme.Spacing.md) {
                                    ForEach(campaignManager.campaigns, id: \.objectID) { campaign in
                                        ModernCampaignCard(campaign: campaign, isActive: false) {
                                            selectedCampaign = campaign
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                    .background(AppTheme.background)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(AppTheme.background)
            .navigationTitle("Campaigns")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingCreateCampaign = true
                        } label: {
                            Label("New Campaign", systemImage: "plus.circle")
                        }
                        .disabled(!canCreateCampaign)

                        Divider()

                        Button {
                            if let url = URL(string: "https://www.icloud.com/shortcuts/5f30c7cc985a4b5eb1bf6fcf06b01f01") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            Label("Get BulkMess Shortcut", systemImage: "square.and.arrow.down")
                        }

                        if !canCreateCampaign {
                            Divider()
                            Text("Add contacts first")
                                .foregroundColor(.secondary)
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateCampaign) {
                CreateCampaignView()
            }
            .sheet(item: $selectedCampaign) { campaign in
                CampaignDetailView(campaign: campaign)
            }

            if hSizeClass == .regular, !campaignManager.campaigns.isEmpty {
                CampaignDetailPlaceholderView()
            }
        }
    }

    private func deleteCampaigns(offsets: IndexSet) {
        for index in offsets {
            campaignManager.deleteCampaign(campaignManager.campaigns[index])
        }
    }
}

struct ModernCampaignCard: View {
    let campaign: Campaign
    let isActive: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.lg) {
                IconBadge(campaignIcon, color: campaignIconColor, size: 50)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(campaign.name ?? "Untitled Campaign")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let template = campaign.template {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "doc.text.fill")
                                .font(.caption)
                                .foregroundColor(AppTheme.accent)
                            Text(template.name ?? "Unknown Template")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }

                    if let dateCreated = campaign.dateCreated {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "clock")
                                .font(.caption)
                                .foregroundColor(AppTheme.accent)
                            Text(dateCreated, style: .relative)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }

                Spacer()

                ModernCampaignStatusBadge(status: campaign.status ?? "unknown")
            }

            // Progress bar for active campaigns
            if campaign.status == "sending" && campaign.totalRecipients > 0 {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Text("Progress")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                        Text("\(campaign.sentCount)/\(campaign.totalRecipients)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.primary)
                    }

                    ProgressView(value: Double(campaign.sentCount), total: Double(campaign.totalRecipients))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                        .scaleEffect(y: 1.5)
                }
                .padding(AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppTheme.accent.opacity(0.05))
                )
            }

            // Campaign metrics
            HStack(spacing: AppTheme.Spacing.lg) {
                CampaignMetric(
                    icon: "person.2.fill",
                    label: "Recipients",
                    value: "\(campaign.totalRecipients)",
                    color: AppTheme.accent
                )

                if campaign.sentCount > 0 {
                    CampaignMetric(
                        icon: "checkmark.circle.fill",
                        label: "Sent",
                        value: "\(campaign.sentCount)",
                        color: AppTheme.success
                    )
                }

                if campaign.failedCount > 0 {
                    CampaignMetric(
                        icon: "xmark.circle.fill",
                        label: "Failed",
                        value: "\(campaign.failedCount)",
                        color: AppTheme.error
                    )
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(AppAnimations.bouncy, value: isPressed)
            }
        }
        .cardContainer()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppAnimations.spring, value: isPressed)
        .onTapGesture {
            withAnimation(AppAnimations.subtle) {
                isPressed = true
            }

            // Call the provided onTap action
            onTap()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(AppAnimations.subtle) {
                    isPressed = false
                }
            }
        }
    }

    private var campaignIcon: String {
        switch campaign.status?.lowercased() {
        case "sending":
            return "paperplane.fill"
        case "completed":
            return "checkmark.circle.fill"
        case "failed":
            return "xmark.circle.fill"
        case "draft":
            return "doc.fill"
        default:
            return "megaphone.fill"
        }
    }

    private var campaignIconColor: Color {
        switch campaign.status?.lowercased() {
        case "sending":
            return AppTheme.accent
        case "completed":
            return AppTheme.success
        case "failed":
            return AppTheme.error
        case "draft":
            return AppTheme.secondaryText
        default:
            return AppTheme.warning
        }
    }
}

struct CampaignMetric: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppTheme.Typography.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Text(label)
                    .font(.caption2)
                    .foregroundColor(AppTheme.secondaryText)
            }
        }
    }
}

struct ModernCampaignStatusBadge: View {
    let status: String

    var body: some View {
        StatusPill(
            text: status.capitalized,
            background: backgroundColor,
            foreground: backgroundColor
        )
    }

    private var backgroundColor: Color {
        switch status.lowercased() {
        case "draft":
            return AppTheme.secondaryText
        case "sending":
            return AppTheme.accent
        case "completed":
            return AppTheme.success
        case "completed_with_errors":
            return AppTheme.warning
        case "failed":
            return AppTheme.error
        default:
            return AppTheme.secondaryText
        }
    }
}

// Keep the old view for backward compatibility
struct CampaignRowView: View {
    let campaign: Campaign
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        ModernCampaignCard(campaign: campaign, isActive: isActive, onTap: onTap)
    }
}

struct CampaignStatusBadge: View {
    let status: String

    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .cornerRadius(8)
    }

    private var backgroundColor: Color {
        switch status.lowercased() {
        case "draft":
            return Color.gray.opacity(0.2)
        case "sending":
            return Color.blue.opacity(0.2)
        case "completed":
            return Color.green.opacity(0.2)
        case "completed_with_errors":
            return Color.orange.opacity(0.2)
        case "failed":
            return Color.red.opacity(0.2)
        default:
            return Color.gray.opacity(0.2)
        }
    }

    private var textColor: Color {
        switch status.lowercased() {
        case "draft":
            return .gray
        case "sending":
            return .blue
        case "completed":
            return .green
        case "completed_with_errors":
            return .orange
        case "failed":
            return .red
        default:
            return .gray
        }
    }
}

struct CampaignProgressView: View {
    let campaign: Campaign

    var progress: Double {
        guard campaign.totalRecipients > 0 else { return 0 }
        return Double(campaign.sentCount + campaign.failedCount) / Double(campaign.totalRecipients)
    }

    var body: some View {
        HStack(spacing: 4) {
            Text("\(campaign.sentCount)/\(campaign.totalRecipients)")
                .font(.caption)
                .fontWeight(.medium)

            if campaign.failedCount > 0 {
                Text("(\(campaign.failedCount) failed)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
}

struct CampaignsEmptyStateView: View {
    @Binding var showingCreateCampaign: Bool
    let canCreateCampaign: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("No Campaigns Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Create your first campaign to send bulk messages to multiple contacts at once")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                if canCreateCampaign {
                    Button {
                        showingCreateCampaign = true
                    } label: {
                        Label("Create Campaign", systemImage: "plus.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                } else {
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("Before creating campaigns:")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            HStack {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 20)
                                Text("Create message templates")
                                    .foregroundColor(.secondary)
                            }
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(.green)
                                    .frame(width: 20)
                                Text("Add or import contacts")
                                    .foregroundColor(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                }

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Campaign features:")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.blue)
                                .frame(width: 16)
                            Text("Batch sending with delays")
                        }
                        HStack {
                            Image(systemName: "chart.bar.fill")
                                .foregroundColor(.orange)
                                .frame(width: 16)
                            Text("Real-time analytics")
                        }
                        HStack {
                            Image(systemName: "square.and.arrow.up.on.square")
                                .foregroundColor(.orange)
                                .frame(width: 16)
                            Text("Send via Apple Shortcuts")
                        }
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.purple)
                                .frame(width: 16)
                            Text("Schedule campaigns")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                // Shortcut Download Button
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
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct CampaignDetailPlaceholderView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "megaphone")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Select a Campaign")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Choose a campaign to view its progress and details")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(AppTheme.background)
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.template(ctx, name: "Promo", content: "Hi {{firstName}}, check this out")
        let contacts = (1...3).map { i in
            PreviewSeed.contact(ctx, firstName: "User\(i)", lastName: "Test", phone: "+15550\(10+i)")
        }
        _ = PreviewSeed.group(ctx, name: "VIP", colorHex: "#007AFF", contacts: contacts)
        // campaign created after env to use manager (post-fetch)
        // This will be initialized below using env.campaignManager
    }
    // Create a sample campaign using the manager so it's reflected in manager state
    if let t = env.templateManager.templates.first, let g = env.contactManager.contactGroups.first {
        _ = env.campaignManager.createCampaign(name: "Fall Launch", template: t, targetGroups: [g], scheduledDate: nil)
    }
    return CampaignsView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.campaignManager)
        .environmentObject(env.templateManager)
        .environmentObject(env.contactManager)
}
