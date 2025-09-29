import SwiftUI

struct AddTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager

    @State private var templateName = ""
    @State private var templateContent = ""
    @State private var showingPlaceholders = false
    @State private var selectedPlaceholder: PlaceholderInfo?
    // Removed unused focus state

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
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xl) {
                    // Template Information Card
                    SectionCard(title: "Template Information", subtitle: "Give your template a descriptive name") {
                        ModernTextField(
                            title: "Template Name",
                            text: $templateName,
                            placeholder: "Welcome Message",
                            icon: "doc.text.fill"
                        )
                    }

                    // Message Content Card
                    SectionCard(title: "Message Content", subtitle: "Write your message with placeholders") {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            CursorAwareModernTextEditor(
                                title: "Message Text",
                                text: $templateContent,
                                placeholder: "Write your message...",
                                characterCount: templateContent.count,
                                onInsertPlaceholder: { placeholder in
                                    insertPlaceholder(placeholder)
                                }
                            )
                        }
                    }

                    // Placeholders Card
                    SectionCard(title: "Add Dynamic Content", subtitle: "Tap to insert") {
                        LazyVGrid(columns: [
                            GridItem(.adaptive(minimum: 160))
                        ], spacing: AppTheme.Spacing.md) {
                            ForEach(placeholders, id: \.placeholder) { placeholder in
                                ModernPlaceholderChip(placeholder: placeholder) {
                                    NotificationCenter.default.post(
                                        name: .insertPlaceholder,
                                        object: placeholder.placeholder
                                    )
                                }
                            }
                        }
                    }

                    // Preview Card
                    if !templateContent.isEmpty && !contactManager.contacts.isEmpty,
                       let firstContact = contactManager.contacts.first {
                        SectionCard(title: "Live Preview", subtitle: "See how your template will look") {
                            ModernTemplatePreviewCard(
                                templateContent: templateContent,
                                contact: firstContact
                            )
                        }
                    }

                    // Save Button
                    if isValidTemplate {
                        Button {
                            saveTemplate()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Save Template")
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
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(!isValidTemplate)
                }
            }
        }
    }

    private var isValidTemplate: Bool {
        !templateName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !templateContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func insertPlaceholder(_ placeholder: String) {
        // This will be handled by the CursorAwareModernTextEditor
        // The function is called by the text editor component itself
    }

    private func saveTemplate() {
        let trimmedName = templateName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContent = templateContent.trimmingCharacters(in: .whitespacesAndNewlines)

        templateManager.createTemplate(name: trimmedName, content: trimmedContent)
        dismiss()
    }
}

// MARK: - Modern Form Components

struct CursorAwareModernTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let characterCount: Int
    let onInsertPlaceholder: (String) -> Void
    @State private var cursorPosition: Int = 0

    // Method to insert text at cursor position
    func insertPlaceholder(_ placeholder: String) {
        let position = min(cursorPosition, text.count)
        let index = text.index(text.startIndex, offsetBy: position)

        // Add space before if needed
        let needsSpaceBefore = position > 0 && !text[text.index(text.startIndex, offsetBy: position - 1)].isWhitespace
        let prefixSpace = needsSpaceBefore ? " " : ""

        // Add space after if needed
        let needsSpaceAfter = position < text.count && !text[index].isWhitespace
        let suffixSpace = needsSpaceAfter ? " " : ""

        let textToInsert = prefixSpace + placeholder + suffixSpace
        text.insert(contentsOf: textToInsert, at: index)

        // The CursorAwareTextEditor will automatically position the cursor at the end of the inserted text
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "text.alignleft")
                    .font(.title3)
                    .foregroundColor(AppTheme.accent)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(AppTheme.secondaryText)
                            .font(AppTheme.Typography.body)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.md + 2)
                    }

                    CursorAwareTextEditor(
                        text: $text,
                        placeholder: placeholder,
                        onCursorPositionChange: { position in
                            DispatchQueue.main.async {
                                cursorPosition = position
                            }
                        }
                    )
                    .frame(minHeight: 120)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(AppTheme.accent.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )

                HStack {
                    Spacer()
                    Text("\(characterCount) characters")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .insertPlaceholder)) { notification in
            if let placeholder = notification.object as? String {
                insertPlaceholder(placeholder)
            }
        }
    }
}

struct ModernTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let characterCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "text.alignleft")
                    .font(.title3)
                    .foregroundColor(AppTheme.accent)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(AppTheme.secondaryText)
                            .font(AppTheme.Typography.body)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.md + 2)
                    }

                    TextEditor(text: $text)
                        .font(AppTheme.Typography.body)
                        .padding(AppTheme.Spacing.md)
                        .frame(minHeight: 120)
                        .background(Color.clear)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(AppTheme.accent.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )

                HStack {
                    Spacer()
                    Text("\(characterCount) characters")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }
}

struct ModernPlaceholderChip: View {
    let placeholder: PlaceholderInfo
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    Image(systemName: "curlybraces")
                        .font(.caption)
                        .foregroundColor(AppTheme.accent)
                    Text(placeholder.placeholder)
                        .font(AppTheme.Typography.callout)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.accent)
                }

                Text(placeholder.description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(AppTheme.accent.opacity(isPressed ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .animation(AppAnimations.subtle, value: isPressed)
        .onTapGesture {
            // Immediate visual feedback
            withAnimation(AppAnimations.subtle) {
                isPressed = true
            }

            // Call the action
            onTap()

            // Reset the pressed state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimations.subtle) {
                    isPressed = false
                }
            }
        }
    }
}

struct ModernTemplatePreviewCard: View {
    let templateContent: String
    let contact: Contact
    @EnvironmentObject var templateManager: MessageTemplateManager

    var body: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            // Contact Info
            HStack(spacing: AppTheme.Spacing.lg) {
                IconBadge("person.fill", color: AppTheme.success, size: 44)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Preview for \(contactName)")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)

                    Text("Sample recipient")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }

                Spacer()

                Image(systemName: "eye")
                    .font(.title2)
                    .foregroundColor(AppTheme.accent)
            }

            // Preview Text
            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text("Processed Message")
                    .font(AppTheme.Typography.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(previewText)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.primary)
                    .padding(AppTheme.Spacing.lg)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .fill(AppTheme.success.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                    .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                            )
                    )
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
        var processedContent: String = templateContent

        // Replace new simplified placeholders with sample data
        processedContent = processedContent.replacingOccurrences(
            of: "{name}",
            with: contact.firstName ?? "John"
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{last}",
            with: contact.lastName ?? "Doe"
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{full}",
            with: contactName
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{phone}",
            with: contact.phoneNumber ?? ""
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{email}",
            with: contact.email ?? "john.doe@example.com"
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{date}",
            with: DateFormatter.mediumDate.string(from: Date())
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{time}",
            with: DateFormatter.shortTime.string(from: Date())
        )

        // Legacy placeholders for backward compatibility
        processedContent = processedContent.replacingOccurrences(
            of: "{{firstName}}",
            with: contact.firstName ?? "John"
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{{lastName}}",
            with: contact.lastName ?? "Doe"
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{{fullName}}",
            with: contactName
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{{phoneNumber}}",
            with: contact.phoneNumber ?? ""
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{{email}}",
            with: contact.email ?? "john.doe@example.com"
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{{currentDate}}",
            with: DateFormatter.mediumDate.string(from: Date())
        )
        processedContent = processedContent.replacingOccurrences(
            of: "{{currentTime}}",
            with: DateFormatter.shortTime.string(from: Date())
        )

        return processedContent
    }
}

// Keep for backward compatibility
struct PlaceholderChip: View {
    let placeholder: PlaceholderInfo
    let onTap: () -> Void

    var body: some View {
        ModernPlaceholderChip(placeholder: placeholder, onTap: onTap)
    }
}

// Keep for backward compatibility
struct TemplatePreviewCard: View {
    let templateContent: String
    let contact: Contact
    @EnvironmentObject var templateManager: MessageTemplateManager

    var body: some View {
        ModernTemplatePreviewCard(templateContent: templateContent, contact: contact)
    }
}

// MARK: - Extensions

extension Notification.Name {
    static let insertPlaceholder = Notification.Name("insertPlaceholder")
}

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    let pc = PersistenceController.preview
    let ctx = pc.container.viewContext
    let c = Contact(context: ctx)
    c.firstName = "Alice"; c.lastName = "Kim"; c.phoneNumber = "+15554444"; c.dateCreated = Date()
    try? ctx.save()
    let templateManager = MessageTemplateManager(persistenceController: pc)
    let contactManager = ContactManager(persistenceController: pc)
    return AddTemplateView()
        .environment(\.managedObjectContext, ctx)
        .environmentObject(templateManager)
        .environmentObject(contactManager)
}
