import SwiftUI

struct TemplateDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager

    let template: MessageTemplate
    @State private var isEditing = false

    var body: some View {
        NavigationStack {
            VStack {
                if isEditing {
                    EditTemplateView(template: template, isEditing: $isEditing)
                } else {
                    TemplateDetailContentView(template: template)
                }
            }
            .navigationTitle(template.name ?? "Template")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            isEditing.toggle()
                        } label: {
                            Label("Edit Template", systemImage: "pencil")
                        }

                        Button {
                            templateManager.toggleTemplateFavorite(template)
                        } label: {
                            Label(
                                template.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: template.isFavorite ? "heart.slash" : "heart"
                            )
                        }

                        Divider()

                        Button(role: .destructive) {
                            templateManager.deleteTemplate(template)
                            dismiss()
                        } label: {
                            Label("Delete Template", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }
}

struct TemplateDetailContentView: View {
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager

    let template: MessageTemplate
    @State private var selectedPreviewContact: Contact?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(template.name ?? "Untitled Template")
                                .font(.title2)
                                .fontWeight(.semibold)

                            if template.isFavorite {
                                Label("Favorite", systemImage: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }

                        Spacer()

                        Button {
                            templateManager.toggleTemplateFavorite(template)
                        } label: {
                            Image(systemName: template.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(template.isFavorite ? .red : .gray)
                                .font(.title2)
                        }
                    }

                    HStack(spacing: AppTheme.Spacing.lg) {
                        StatisticView(
                            title: "Uses",
                            value: "\(template.usageCount)",
                            icon: "arrow.up.circle"
                        )

                        StatisticView(
                            title: "Characters",
                            value: "\(template.content?.count ?? 0)",
                            icon: "textformat.abc"
                        )

                        if let campaigns = template.campaigns, campaigns.count > 0 {
                            StatisticView(
                                title: "Campaigns",
                                value: "\(campaigns.count)",
                                icon: "megaphone.fill"
                            )
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section("Message Content") {
                Text(template.content ?? "")
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            if !contactManager.contacts.isEmpty {
                Section {
                    Button {
                        selectedPreviewContact = contactManager.contacts.first
                    } label: {
                        Label("Preview with Sample Contact", systemImage: "eye")
                    }
                } header: {
                    Text("Preview")
                } footer: {
                    Text("See how your message looks with real contact data.")
                }
            }

            Section("Template Placeholders") {
                let placeholders = extractPlaceholders(from: template.content ?? "")
                if placeholders.isEmpty {
                    Text("No dynamic content found")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(placeholders, id: \.self) { placeholder in
                        HStack {
                            Text(placeholder)
                                .font(.monospaced(.body)())
                                .foregroundColor(.blue)

                            Spacer()

                            Text(getPlaceholderDescription(placeholder))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Section("Metadata") {
                MetadataRow(
                    label: "Created",
                    value: DateFormatter.fullDateTime.string(from: template.dateCreated ?? Date()),
                    icon: "calendar"
                )

                MetadataRow(
                    label: "Last Modified",
                    value: DateFormatter.fullDateTime.string(from: template.dateModified ?? Date()),
                    icon: "pencil.circle"
                )

                MetadataRow(
                    label: "Usage Count",
                    value: "\(template.usageCount) times",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .sheet(item: $selectedPreviewContact) { contact in
            TemplatePreviewSheet(template: template, contact: contact)
        }
    }

    private func extractPlaceholders(from content: String) -> [String] {
        // Pattern matches both new {name} and legacy {{name}} formats
        let pattern = "\\{\\{?[^}]+\\}\\}?"
        let regex = try? NSRegularExpression(pattern: pattern)
        let range = NSRange(content.startIndex..., in: content)
        let matches = regex?.matches(in: content, range: range) ?? []

        var placeholders: Set<String> = []
        for match in matches {
            if let range = Range(match.range, in: content) {
                placeholders.insert(String(content[range]))
            }
        }

        return Array(placeholders).sorted()
    }

    private func getPlaceholderDescription(_ placeholder: String) -> String {
        switch placeholder {
        case "{name}":
            return "First name"
        case "{last}":
            return "Last name"
        case "{full}":
            return "Full name"
        case "{phone}":
            return "Phone number"
        case "{email}":
            return "Email"
        case "{date}":
            return "Today's date"
        case "{time}":
            return "Current time"
        // Legacy support
        case "{{firstName}}":
            return "First name"
        case "{{lastName}}":
            return "Last name"
        case "{{fullName}}":
            return "Full name"
        case "{{phoneNumber}}":
            return "Phone number"
        case "{{currentDate}}":
            return "Today's date"
        case "{{currentTime}}":
            return "Current time"
        default:
            return "Custom"
        }
    }
}

struct EditTemplateView: View {
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager

    let template: MessageTemplate
    @Binding var isEditing: Bool

    @State private var templateName: String
    @State private var templateContent: String

    init(template: MessageTemplate, isEditing: Binding<Bool>) {
        self.template = template
        self._isEditing = isEditing

        self._templateName = State(initialValue: template.name ?? "")
        self._templateContent = State(initialValue: template.content ?? "")
    }

    private let placeholders = [
        PlaceholderInfo(placeholder: "{name}", description: "First name"),
        PlaceholderInfo(placeholder: "{last}", description: "Last name"),
        PlaceholderInfo(placeholder: "{full}", description: "Full name"),
        PlaceholderInfo(placeholder: "{phone}", description: "Phone number"),
        PlaceholderInfo(placeholder: "{email}", description: "Email"),
        PlaceholderInfo(placeholder: "{date}", description: "Today's date"),
        PlaceholderInfo(placeholder: "{time}", description: "Current time")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Template Information") {
                    TextField("Template Name", text: $templateName)
                        .textInputAutocapitalization(.words)
                }

                Section("Message Content") {
                    TextEditor(text: $templateContent)
                        .frame(minHeight: 120)
                }

                Section("Quick Add Placeholders") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 140))
                    ], spacing: 8) {
                        ForEach(placeholders, id: \.placeholder) { placeholder in
                            PlaceholderChip(placeholder: placeholder) {
                                insertPlaceholder(placeholder.placeholder)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                if !templateContent.isEmpty && !contactManager.contacts.isEmpty,
                   let firstContact = contactManager.contacts.first {
                    Section("Preview") {
                        TemplatePreviewCard(
                            templateContent: templateContent,
                            contact: firstContact
                        )
                    }
                }

                Section {
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .foregroundColor(.blue)
                    .disabled(!isValidTemplate)
                }
            }

            HStack {
                Spacer()
                Text("\(templateContent.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private var isValidTemplate: Bool {
        !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !templateContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func insertPlaceholder(_ placeholder: String) {
        templateContent += templateContent.isEmpty ? placeholder : " \(placeholder)"
    }

    private func saveChanges() {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = templateContent.trimmingCharacters(in: .whitespacesAndNewlines)

        templateManager.updateTemplate(template, name: trimmedName, content: trimmedContent)
        isEditing = false
    }
}

struct StatisticView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

struct TemplatePreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var templateManager: MessageTemplateManager

    let template: MessageTemplate
    let contact: Contact

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Preview for \(contactName)")
                        .font(.headline)

                    Text("Template: \(template.name ?? "Untitled")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ScrollView {
                    Text(previewText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
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

    private var contactName: String {
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

    private var previewText: String {
        return templateManager.processTemplate(template, for: contact)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let fullDateTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.template(ctx, name: "Follow Up", content: "Hello {{fullName}}, just checking in")
        _ = PreviewSeed.contact(ctx, firstName: "Rita", lastName: "Ng", phone: "+15557777")
    }
    return TemplateDetailView(template: env.templateManager.templates.first!)
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.templateManager)
        .environmentObject(env.contactManager)
}
