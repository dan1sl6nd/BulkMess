import Foundation
import CoreData

class MessageTemplateManager: ObservableObject {
    @Published var templates: [MessageTemplate] = []

    private let persistenceController: PersistenceController
    private static let formatterQueue = DispatchQueue(label: "com.bulkmess.MessageTemplateManager.formatters")
    private static let cachedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        return formatter
    }()
    private static let cachedTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = .autoupdatingCurrent
        return formatter
    }()

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        loadTemplates()
    }

    // MARK: - Template Management

    func createTemplate(name: String, content: String) {
        let context = persistenceController.container.viewContext

        let template = MessageTemplate(context: context)
        template.name = name
        template.content = content
        template.dateCreated = Date()
        template.dateModified = Date()
        template.isFavorite = false
        template.usageCount = 0

        do {
            try context.save()
            loadTemplates()
        } catch {
            print("Error creating template: \(error)")
        }
    }

    func updateTemplate(_ template: MessageTemplate, name: String, content: String) {
        template.name = name
        template.content = content
        template.dateModified = Date()

        do {
            try persistenceController.container.viewContext.save()
            loadTemplates()
        } catch {
            print("Error updating template: \(error)")
        }
    }

    func deleteTemplate(_ template: MessageTemplate) {
        let context = persistenceController.container.viewContext
        context.delete(template)

        do {
            try context.save()
            loadTemplates()
        } catch {
            print("Error deleting template: \(error)")
        }
    }

    func toggleTemplateFavorite(_ template: MessageTemplate) {
        template.isFavorite.toggle()

        do {
            try persistenceController.container.viewContext.save()
            loadTemplates()
        } catch {
            print("Error toggling template favorite: \(error)")
        }
    }

    func incrementTemplateUsage(_ template: MessageTemplate) {
        template.usageCount += 1

        do {
            try persistenceController.container.viewContext.save()
        } catch {
            print("Error incrementing template usage: \(error)")
        }
    }

    // MARK: - Message Processing

    func processTemplate(_ template: MessageTemplate, for contact: Contact) -> String {
        let templateContent: String = template.content ?? ""
        var processedContent: String = templateContent

        let firstName = contact.firstName ?? ""
        let lastName = contact.lastName ?? ""
        let fullName = getFullName(for: contact)
        let phone = contact.phoneNumber ?? ""
        let email = contact.email ?? ""

        let now = Date()
        let (dateString, timeString) = Self.formatterQueue.sync {
            (
                Self.cachedDateFormatter.string(from: now),
                Self.cachedTimeFormatter.string(from: now)
            )
        }

        let replacements: [(placeholder: String, value: String)] = [
            ("{name}", firstName),
            ("{last}", lastName),
            ("{full}", fullName),
            ("{phone}", phone),
            ("{email}", email),
            ("{{firstName}}", firstName),
            ("{{lastName}}", lastName),
            ("{{fullName}}", fullName),
            ("{{phoneNumber}}", phone),
            ("{{email}}", email),
            ("{date}", dateString),
            ("{time}", timeString),
            ("{{currentDate}}", dateString),
            ("{{currentTime}}", timeString)
        ]

        for (placeholder, value) in replacements {
            guard processedContent.contains(placeholder) else { continue }
            processedContent = processedContent.replacingOccurrences(of: placeholder, with: value)
        }

        return processedContent
    }

    func getAvailablePlaceholders() -> [PlaceholderInfo] {
        return [
            PlaceholderInfo(placeholder: "{name}", description: "First name"),
            PlaceholderInfo(placeholder: "{last}", description: "Last name"),
            PlaceholderInfo(placeholder: "{full}", description: "Full name"),
            PlaceholderInfo(placeholder: "{phone}", description: "Phone number"),
            PlaceholderInfo(placeholder: "{email}", description: "Email"),
            PlaceholderInfo(placeholder: "{date}", description: "Today's date"),
            PlaceholderInfo(placeholder: "{time}", description: "Current time")
        ]
    }

    func previewTemplate(_ template: MessageTemplate, with contact: Contact) -> String {
        return processTemplate(template, for: contact)
    }

    // MARK: - Data Loading and Utility

    private func loadTemplates() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<MessageTemplate> = MessageTemplate.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \MessageTemplate.isFavorite, ascending: false),
            NSSortDescriptor(keyPath: \MessageTemplate.dateModified, ascending: false)
        ]

        do {
            templates = try context.fetch(request)
        } catch {
            print("Error loading templates: \(error)")
        }
    }

    private func getFullName(for contact: Contact) -> String {
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

    func searchTemplates(_ searchText: String) -> [MessageTemplate] {
        if searchText.isEmpty {
            return templates
        }

        return templates.filter { template in
            let templateName = template.name ?? ""
            let templateContent = template.content ?? ""
            return templateName.lowercased().contains(searchText.lowercased()) ||
                   templateContent.lowercased().contains(searchText.lowercased())
        }
    }

    func getFavoriteTemplates() -> [MessageTemplate] {
        return templates.filter { $0.isFavorite }
    }

    func getMostUsedTemplates(limit: Int = 5) -> [MessageTemplate] {
        return templates.sorted { $0.usageCount > $1.usageCount }.prefix(limit).map { $0 }
    }
}

struct PlaceholderInfo {
    let placeholder: String
    let description: String
}
