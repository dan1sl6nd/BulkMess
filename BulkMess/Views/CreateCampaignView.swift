import SwiftUI

struct CreateCampaignView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var campaignManager: CampaignManager
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager

    @State private var campaignName = ""
    @State private var selectedTemplate: MessageTemplate?
    @State private var previewTemplate: MessageTemplate?
    @State private var selectedGroups: Set<ContactGroup> = []
    @State private var scheduleDate: Date = Date()
    @State private var isScheduled = false

    @State private var showingGroupSelection = false
    @State private var showingAddTemplate = false

    var recipientCount: Int {
        let allContacts = Set(selectedGroups.flatMap { $0.contactsArray })
        return allContacts.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xl) {
                    // Campaign Details Card
                    SectionCard(title: "Campaign Details", subtitle: "Give your campaign a memorable name") {
                        ModernTextField(
                            title: "Campaign Name",
                            text: $campaignName,
                            placeholder: "Summer Sale Announcement",
                            icon: "megaphone.fill"
                        )
                    }

                    // Template Selection Card
                    SectionCard(title: "Message Template", subtitle: "Choose or preview your template") {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            ModernTemplatePicker(
                                selectedTemplate: $selectedTemplate,
                                templates: templateManager.templates,
                                showingAddTemplate: $showingAddTemplate
                            )

                            if selectedTemplate != nil {
                                Button {
                                    previewTemplate = selectedTemplate
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "eye")
                                        Text("Preview Template")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }
                        }
                    }

                    // Recipients Card
                    SectionCard(
                        title: "Recipients",
                        subtitle: selectedGroups.isEmpty ? "Select contact groups to send messages to" : "Messages will be sent to \(recipientCount) unique contacts"
                    ) {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            if selectedGroups.isEmpty {
                                Button {
                                    showingGroupSelection = true
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "person.2.badge.plus")
                                        Text("Select Contact Groups")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            } else {
                                Button {
                                    showingGroupSelection = true
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        Image(systemName: "person.2.badge.plus")
                                        Text("Select Contact Groups")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                            }

                            if !selectedGroups.isEmpty {
                                VStack(spacing: AppTheme.Spacing.md) {
                                    ForEach(Array(selectedGroups), id: \.objectID) { group in
                                        ModernGroupSelectionRow(group: group)
                                    }

                                    ModernRecipientSummary(count: recipientCount)
                                }
                            }
                        }
                    }

                    // Scheduling Card
                    SectionCard(title: "Scheduling", subtitle: "Send now or schedule for later") {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            ModernToggleRow(
                                title: "Schedule for later",
                                subtitle: "Send at a specific time",
                                icon: "clock.fill",
                                isOn: $isScheduled
                            )

                            if isScheduled {
                                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                                    Text("Send Date & Time")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(.primary)

                                    DatePicker("Send Date", selection: $scheduleDate, in: Date()...)
                                        .datePickerStyle(.compact)
                                        .padding(AppTheme.Spacing.md)
                                        .background(
                                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                                .fill(AppTheme.accent.opacity(0.05))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                                        .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                        }
                    }

                    // Create Button
                    if canCreateCampaign {
                        Button {
                            createCampaign()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Create Campaign")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.sm)
            }
            .background(AppTheme.background)
            .navigationTitle("New Campaign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingGroupSelection) {
                ModernGroupSelectionView(selectedGroups: $selectedGroups)
            }
            .sheet(isPresented: $showingAddTemplate) {
                AddTemplateView()
            }
            .sheet(item: $previewTemplate) { template in
                ModernTemplatePreviewForCampaign(template: template)
            }
        }
    }

    private var canCreateCampaign: Bool {
        !campaignName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !selectedGroups.isEmpty
    }

    private func createCampaign() {
        let trimmedName = campaignName.trimmingCharacters(in: .whitespacesAndNewlines)
        let scheduledDate = isScheduled ? scheduleDate : nil

        _ = campaignManager.createCampaign(
            name: trimmedName,
            template: selectedTemplate,
            targetGroups: Array(selectedGroups),
            scheduledDate: scheduledDate
        )

        dismiss()
    }
}

// MARK: - Modern Form Components

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(AppTheme.accent)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.words)
                .padding(AppTheme.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(AppTheme.accent.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
}

struct ModernTemplatePicker: View {
    @Binding var selectedTemplate: MessageTemplate?
    let templates: [MessageTemplate]
    @Binding var showingAddTemplate: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "doc.text.fill")
                        .font(.title3)
                        .foregroundColor(AppTheme.accent)
                    Text("Choose Template")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                }
                Spacer()
                Button {
                    showingAddTemplate = true
                } label: {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "plus")
                        Text("New")
                    }
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if templates.isEmpty {
                EmptyStateCard(
                    icon: "doc.text.fill",
                    title: "No Templates",
                    message: "Create a template to use in this campaign",
                    buttonTitle: "Create Template",
                    buttonAction: { showingAddTemplate = true },
                    accentColor: AppTheme.accent
                )
            } else {
                VStack(spacing: AppTheme.Spacing.sm) {
                    ForEach(templates, id: \.objectID) { template in
                        ModernTemplateSelectionRow(
                            template: template,
                            isSelected: selectedTemplate == template
                        ) {
                            selectedTemplate = template
                        }
                    }
                }
            }
        }
    }
}

struct ModernTemplateSelectionRow: View {
    let template: MessageTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: AppTheme.Spacing.lg) {
                IconBadge("doc.text.fill", color: AppTheme.accent, size: 40)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(template.name ?? "Untitled")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if let content = template.content {
                        Text(content)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .lineLimit(2)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.secondaryText)
            }
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(isSelected ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .stroke(isSelected ? AppTheme.accent.opacity(0.3) : AppTheme.accent.opacity(0.1), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct ModernGroupSelectionRow: View {
    let group: ContactGroup

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Circle()
                .fill(Color(hex: group.colorHex ?? "#007AFF"))
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(group.name ?? "Unknown Group")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)

                Text("\(group.contactsArray.count) contacts")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()
        }
        .settingsCard()
    }
}

struct ModernRecipientSummary: View {
    let count: Int

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            IconBadge("person.2.fill", color: AppTheme.success, size: 44)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Total Recipients")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)

                Text("Unique contacts to receive messages")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            Text("\(count)")
                .font(AppTheme.Typography.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.accent)
        }
        .metricCard(accentColor: AppTheme.success)
    }
}

struct ModernToggleRow: View {
    let title: String
    let subtitle: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            IconBadge(icon, color: AppTheme.warning, size: 44)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
        .settingsCard()
    }
}

struct ModernGroupSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    @Binding var selectedGroups: Set<ContactGroup>

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if contactManager.contactGroups.isEmpty {
                    EmptyStateCard(
                        icon: "folder",
                        title: "No Contact Groups",
                        message: "Create contact groups first to organize your recipients",
                        accentColor: AppTheme.accent
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(contactManager.contactGroups, id: \.objectID) { group in
                                ModernGroupSelectionCard(
                                    group: group,
                                    isSelected: selectedGroups.contains(group)
                                ) { isSelected in
                                    if isSelected {
                                        selectedGroups.insert(group)
                                    } else {
                                        selectedGroups.remove(group)
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
            .navigationTitle("Select Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModernGroupSelectionCard: View {
    let group: ContactGroup
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        Button {
            onToggle(!isSelected)
        } label: {
            HStack(spacing: AppTheme.Spacing.lg) {
                IconBadge("folder.fill", color: Color(hex: group.colorHex ?? "#007AFF"), size: 50)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(group.name ?? "Unknown Group")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)

                    Text("\(group.contactsArray.count) contacts")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.secondaryText)
            }
        }
        .buttonStyle(.plain)
        .cardContainer()
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .stroke(isSelected ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// Keep for backward compatibility
struct GroupSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    @Binding var selectedGroups: Set<ContactGroup>

    var body: some View {
        ModernGroupSelectionView(selectedGroups: $selectedGroups)
    }
}

struct GroupSelectionRow: View {
    let group: ContactGroup
    let isSelected: Bool
    let onToggle: (Bool) -> Void

    var body: some View {
        HStack {
            Button {
                onToggle(!isSelected)
            } label: {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .blue : .gray)

                    Circle()
                        .fill(Color(hex: group.colorHex ?? "#007AFF"))
                        .frame(width: 12, height: 12)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.name ?? "Unknown Group")
                            .font(.headline)

                        Text("\(group.contactsArray.count) contacts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
    }
}

struct ModernTemplatePreviewForCampaign: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var templateManager: MessageTemplateManager

    let template: MessageTemplate

    var sampleContact: Contact? {
        contactManager.contacts.first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xl) {
                    if let contact = sampleContact {
                        // Header Card
                        SectionCard(title: "Template Preview", subtitle: "See how your message will look") {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                IconBadge("person.fill", color: AppTheme.accent, size: 50)

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Sample Recipient")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(.primary)

                                    Text(getContactName(contact))
                                        .font(AppTheme.Typography.callout)
                                        .foregroundColor(AppTheme.secondaryText)
                                }

                                Spacer()
                            }
                        }

                        // Original Template Card
                        SectionCard(title: "Original Template", subtitle: "Raw template with placeholders") {
                            Text(template.content ?? "")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(.primary)
                                .padding(AppTheme.Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                        .fill(AppTheme.secondaryText.opacity(0.05))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                                .stroke(AppTheme.secondaryText.opacity(0.1), lineWidth: 1)
                                        )
                                )
                        }

                        // Processed Message Card
                        SectionCard(title: "Processed Message", subtitle: "How the recipient will see it") {
                            Text(templateManager.processTemplate(template, for: contact))
                                .font(AppTheme.Typography.body)
                                .foregroundColor(.primary)
                                .padding(AppTheme.Spacing.lg)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                        .fill(AppTheme.accent.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                                        )
                                )
                        }
                    } else {
                        EmptyStateCard(
                            icon: "person.2",
                            title: "No Contacts",
                            message: "Add contacts to preview template processing",
                            accentColor: AppTheme.accent
                        )
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.sm)
            }
            .background(AppTheme.background)
            .navigationTitle("Template Preview")
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

    private func getContactName(_ contact: Contact) -> String {
        let firstName = contact.firstName ?? ""
        let lastName = contact.lastName ?? ""

        if firstName.isEmpty && lastName.isEmpty {
            return contact.phoneNumber ?? "Unknown"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }
}

// Keep for backward compatibility
struct TemplatePreviewForCampaign: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var templateManager: MessageTemplateManager

    let template: MessageTemplate

    var body: some View {
        ModernTemplatePreviewForCampaign(template: template)
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.template(ctx, name: "Greeting", content: "Hello {{fullName}}")
        let c = PreviewSeed.contact(ctx, firstName: "Ava", lastName: "Stone", phone: "+15559000")
        _ = PreviewSeed.group(ctx, name: "All", colorHex: "#34C759", contacts: [c])
    }
    return CreateCampaignView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.campaignManager)
        .environmentObject(env.templateManager)
        .environmentObject(env.contactManager)
}
