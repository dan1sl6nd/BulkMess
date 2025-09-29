import SwiftUI

struct TemplatePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager

    @State private var selectedTemplate: MessageTemplate?
    @State private var selectedContact: Contact?

    var body: some View {
        NavigationStack {
            VStack {
                if templateManager.templates.isEmpty {
                    ContentUnavailableView(
                        "No Templates",
                        systemImage: "doc.text",
                        description: Text("Create a template first to preview messages.")
                    )
                } else if contactManager.contacts.isEmpty {
                    ContentUnavailableView(
                        "No Contacts",
                        systemImage: "person.2",
                        description: Text("Add contacts to preview how templates will look.")
                    )
                } else {
                    Form {
                        Section("Select Template") {
                            Picker("Template", selection: $selectedTemplate) {
                                Text("Choose a template...")
                                    .tag(nil as MessageTemplate?)

                                ForEach(templateManager.templates, id: \.objectID) { template in
                                    Text(template.name ?? "Untitled")
                                        .tag(template as MessageTemplate?)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        Section("Select Contact") {
                            Picker("Contact", selection: $selectedContact) {
                                Text("Choose a contact...")
                                    .tag(nil as Contact?)

                                ForEach(contactManager.contacts, id: \.objectID) { contact in
                                    Text(getContactDisplayName(contact))
                                        .tag(contact as Contact?)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        if let template = selectedTemplate, let contact = selectedContact {
                            Section("Preview") {
                                PreviewMessageView(template: template, contact: contact)
                            }
                        }
                    }
                }
            }
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
        .onAppear {
            // Auto-select first template and contact if available
            if selectedTemplate == nil && !templateManager.templates.isEmpty {
                selectedTemplate = templateManager.templates.first
            }
            if selectedContact == nil && !contactManager.contacts.isEmpty {
                selectedContact = contactManager.contacts.first
            }
        }
    }

    private func getContactDisplayName(_ contact: Contact) -> String {
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

struct PreviewMessageView: View {
    @EnvironmentObject var templateManager: MessageTemplateManager

    let template: MessageTemplate
    let contact: Contact

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Original template
            VStack(alignment: .leading, spacing: 8) {
                Text("Original Template")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(template.content ?? "")
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            }

            // Processed message
            VStack(alignment: .leading, spacing: 8) {
                Text("Processed Message for \(contactDisplayName)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Text(processedMessage)
                    .padding(12)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            }

            // Placeholder mappings
            VStack(alignment: .leading, spacing: 8) {
                Text("Placeholder Mappings")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(getPlaceholderMappings(), id: \.placeholder) { mapping in
                        PlaceholderMappingView(mapping: mapping)
                    }
                }
            }

            // Message statistics
            HStack(spacing: AppTheme.Spacing.lg) {
                MessageStatView(
                    title: "Characters",
                    value: "\(processedMessage.count)",
                    icon: "textformat.abc"
                )

                MessageStatView(
                    title: "Words",
                    value: "\(processedMessage.split(separator: " ").count)",
                    icon: "text.word.spacing"
                )

                MessageStatView(
                    title: "Lines",
                    value: "\(processedMessage.split(separator: "\n").count)",
                    icon: "text.alignleft"
                )
            }
        }
    }

    private var contactDisplayName: String {
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

    private var processedMessage: String {
        return templateManager.processTemplate(template, for: contact)
    }

    private func getPlaceholderMappings() -> [PlaceholderMapping] {
        let templateContent = template.content ?? ""
        var mappings: [PlaceholderMapping] = []

        // New simplified format
        if templateContent.contains("{name}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{name}",
                value: contact.firstName ?? "(empty)"
            ))
        }

        if templateContent.contains("{last}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{last}",
                value: contact.lastName ?? "(empty)"
            ))
        }

        if templateContent.contains("{full}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{full}",
                value: contactDisplayName
            ))
        }

        if templateContent.contains("{phone}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{phone}",
                value: contact.phoneNumber ?? ""
            ))
        }

        if templateContent.contains("{email}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{email}",
                value: contact.email ?? "(empty)"
            ))
        }

        if templateContent.contains("{date}") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            mappings.append(PlaceholderMapping(
                placeholder: "{date}",
                value: dateFormatter.string(from: Date())
            ))
        }

        if templateContent.contains("{time}") {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            mappings.append(PlaceholderMapping(
                placeholder: "{time}",
                value: timeFormatter.string(from: Date())
            ))
        }

        // Legacy format support
        if templateContent.contains("{{firstName}}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{{firstName}}",
                value: contact.firstName ?? "(empty)"
            ))
        }

        if templateContent.contains("{{lastName}}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{{lastName}}",
                value: contact.lastName ?? "(empty)"
            ))
        }

        if templateContent.contains("{{fullName}}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{{fullName}}",
                value: contactDisplayName
            ))
        }

        if templateContent.contains("{{phoneNumber}}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{{phoneNumber}}",
                value: contact.phoneNumber ?? ""
            ))
        }

        if templateContent.contains("{{email}}") {
            mappings.append(PlaceholderMapping(
                placeholder: "{{email}}",
                value: contact.email ?? "(empty)"
            ))
        }

        if templateContent.contains("{{currentDate}}") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            mappings.append(PlaceholderMapping(
                placeholder: "{{currentDate}}",
                value: dateFormatter.string(from: Date())
            ))
        }

        if templateContent.contains("{{currentTime}}") {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            mappings.append(PlaceholderMapping(
                placeholder: "{{currentTime}}",
                value: timeFormatter.string(from: Date())
            ))
        }

        return mappings
    }
}

struct PlaceholderMappingView: View {
    let mapping: PlaceholderMapping

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(mapping.placeholder)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.blue)

            Text(mapping.value)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(6)
    }
}

struct MessageStatView: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)

            Text(value)
                .font(.caption)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct PlaceholderMapping {
    let placeholder: String
    let value: String
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.template(ctx, name: "Info", content: "Hi {{fullName}} at {{currentTime}}")
        _ = PreviewSeed.contact(ctx, firstName: "Leo", lastName: "Tran", phone: "+15553339")
    }
    return TemplatePreviewView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.templateManager)
        .environmentObject(env.contactManager)
}
