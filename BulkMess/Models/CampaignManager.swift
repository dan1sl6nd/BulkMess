import Foundation
import CoreData
import MessageUI

class CampaignManager: ObservableObject {
    @Published var campaigns: [Campaign] = []
    @Published var isMessageComposerPresented = false

    private let persistenceController: PersistenceController
    private let templateManager: MessageTemplateManager
    private let messagingService: MessagingService
    private let deliverySettings: DeliverySettings
    init(persistenceController: PersistenceController = .shared, templateManager: MessageTemplateManager, messagingService: MessagingService = MessagingService(), deliverySettings: DeliverySettings) {
        self.persistenceController = persistenceController
        self.templateManager = templateManager
        self.messagingService = messagingService
        self.deliverySettings = deliverySettings
        loadCampaigns()
    }

    // MARK: - Campaign Management

    func createCampaign(name: String, template: MessageTemplate?, targetGroups: [ContactGroup], scheduledDate: Date? = nil) -> Campaign {
        let context = persistenceController.container.viewContext

        let campaign = Campaign(context: context)
        campaign.name = name
        campaign.dateCreated = Date()
        campaign.scheduledDate = scheduledDate
        campaign.status = "draft"
        campaign.template = template

        // Add target groups
        for group in targetGroups {
            campaign.addToTargetGroups(group)
        }

        // Calculate total recipients
        let allContacts = Set(targetGroups.flatMap { $0.contactsArray })
        campaign.totalRecipients = Int32(allContacts.count)

        do {
            try context.save()
            loadCampaigns()
            return campaign
        } catch {
            print("Error creating campaign: \(error)")
            return campaign
        }
    }

    func updateCampaign(_ campaign: Campaign, name: String, template: MessageTemplate?, targetGroups: [ContactGroup], scheduledDate: Date?) {
        campaign.name = name
        campaign.template = template
        campaign.scheduledDate = scheduledDate

        // Update target groups safely
        if let existingGroups = campaign.targetGroups {
            campaign.removeFromTargetGroups(existingGroups)
        }
        for group in targetGroups {
            campaign.addToTargetGroups(group)
        }

        // Recalculate total recipients
        let allContacts = Set(targetGroups.flatMap { $0.contactsArray })
        campaign.totalRecipients = Int32(allContacts.count)

        do {
            try persistenceController.container.viewContext.save()
            loadCampaigns()
        } catch {
            print("Error updating campaign: \(error)")
        }
    }

    func deleteCampaign(_ campaign: Campaign) {
        let context = persistenceController.container.viewContext
        context.delete(campaign)

        do {
            try context.save()
            loadCampaigns()
        } catch {
            print("Error deleting campaign: \(error)")
        }
    }

    // MARK: - Message Sending

    func sendCampaignViaAutomatedShortcut(_ campaign: Campaign, method: AutomatedSendingMethod = .autoSend) -> Bool {
        let messages = generateMessagesForCampaign(campaign)
        guard !messages.isEmpty else { return false }

        switch method {
        case .autoSend:
            return ShortcutsService.sendMessagesViaAutomatedShortcut(messages: messages)
        case .batchProcessor(let batchSize, let delaySeconds):
            return ShortcutsService.sendMessagesViaBatchProcessor(
                messages: messages,
                batchSize: batchSize,
                delaySeconds: delaySeconds
            )
        }
    }

    func sendCampaignViaAutomatedMessaging(
        _ campaign: Campaign,
        method: AutomatedSendingMethod = .autoSend,
        automatedMessagingService: AutomatedMessagingService,
        progressCallback: @escaping (AutomatedSendingProgress) -> Void,
        completion: @escaping (Result<AutomatedSendingResult, Error>) -> Void
    ) {
        let messages = generateMessagesForCampaign(campaign)
        guard !messages.isEmpty else {
            completion(.failure(CampaignError.noRecipients))
            return
        }

        campaign.status = "sending"
        campaign.sentCount = 0
        campaign.failedCount = 0

        do {
            try persistenceController.container.viewContext.save()
        } catch {
            completion(.failure(error))
            return
        }

        automatedMessagingService.sendMessagesAutomatically(
            messages: messages,
            method: method,
            progressCallback: progressCallback
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let sendingResult):
                    campaign.sentCount = Int32(sendingResult.totalSent)
                    campaign.failedCount = Int32(sendingResult.totalFailed)
                    campaign.status = sendingResult.totalFailed == 0 ? "completed" : "completed_with_errors"

                    if let template = campaign.template {
                        self?.templateManager.incrementTemplateUsage(template)
                    }


                    try? self?.persistenceController.container.viewContext.save()
                    completion(.success(sendingResult))

                case .failure(let error):
                    campaign.status = "failed"
                    try? self?.persistenceController.container.viewContext.save()
                    completion(.failure(error))
                }
            }
        }
    }

    func sendCampaign(_ campaign: Campaign, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let template = campaign.template else {
            completion(.failure(CampaignError.noTemplate))
            return
        }

        campaign.status = "sending"
        campaign.sentCount = 0
        campaign.failedCount = 0

        // Get all unique contacts from target groups
        let allContacts = Set(campaign.targetGroupsArray.flatMap { $0.contactsArray })

        // Check if we have contacts to send to
        guard !allContacts.isEmpty else {
            campaign.status = "failed"
            completion(.failure(CampaignError.noContacts))
            return
        }

        // Prepare messages for bulk sending - only include contacts with valid phone numbers
        let messages: [(phoneNumber: String, content: String)] = allContacts.compactMap { contact in
            guard let phoneNumber = contact.phoneNumber, !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            let processedContent = templateManager.processTemplate(template, for: contact)
            return (phoneNumber: phoneNumber, content: processedContent)
        }

        // Check if we have any valid messages after filtering
        guard !messages.isEmpty else {
            campaign.status = "failed"
            completion(.failure(CampaignError.noContacts))
            return
        }

        // Save message records to Core Data
        let context = persistenceController.container.viewContext
        var messageRecords: [Message] = []

        // Filter contacts to only those with valid phone numbers
        let validContacts = allContacts.filter { contact in
            guard let phoneNumber = contact.phoneNumber else { return false }
            return !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        for contact in validContacts {
            let message = Message(context: context)
            message.content = templateManager.processTemplate(template, for: contact)
            message.contact = contact
            message.campaign = campaign
            message.status = "pending"
            messageRecords.append(message)
        }

        do {
            try context.save()
        } catch {
            completion(.failure(error))
            return
        }

        // Send messages using MessagingService
        messagingService.sendBulkMessages(
            messages: messages,
            batchSize: 10,
            delayBetweenBatches: 1.0,
            progressCallback: { [weak self] sent, total in
                DispatchQueue.main.async {
                    // Update campaign progress
                    campaign.sentCount = Int32(sent)
                    try? self?.persistenceController.container.viewContext.save()
                }
            }
        ) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let bulkResult):
                    campaign.sentCount = Int32(bulkResult.totalSent)
                    campaign.failedCount = Int32(bulkResult.totalFailed)
                    campaign.status = bulkResult.totalFailed == 0 ? "completed" : "completed_with_errors"

                    // Update individual message statuses
                    for (index, messageRecord) in messageRecords.enumerated() {
                        if index < bulkResult.totalSent {
                            messageRecord.status = "sent"
                            messageRecord.dateSent = Date()
                        } else {
                            messageRecord.status = "failed"
                            messageRecord.errorMessage = "Failed to send"
                        }
                    }

                    self?.templateManager.incrementTemplateUsage(template)
                    try? self?.persistenceController.container.viewContext.save()
                    // Schedule follow-ups if enabled
                    completion(.success(()))

                case .failure(let error):
                    campaign.status = "failed"
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Shortcuts Integration

    func buildMessagesForShortcuts(_ campaign: Campaign) -> [(phone: String, body: String)] {
        guard let template = campaign.template else { return [] }

        // Collect unique contacts across target groups
        let allContacts = Set(campaign.targetGroupsArray.flatMap { $0.contactsArray })
        let messages: [(String, String)] = allContacts.compactMap { contact in
            guard let phone = contact.phoneNumber, !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            let body = templateManager.processTemplate(template, for: contact)
            return (phone, body)
        }
        return messages
    }

    // MARK: - Campaign Analytics

    func getCampaignAnalytics(_ campaign: Campaign) -> CampaignAnalytics {
        let totalMessages = campaign.totalRecipients
        let sentMessages = campaign.sentCount
        let failedMessages = campaign.failedCount
        let pendingMessages = totalMessages - sentMessages - failedMessages

        let successRate = totalMessages > 0 ? Double(sentMessages) / Double(totalMessages) * 100 : 0

        return CampaignAnalytics(
            totalRecipients: Int(totalMessages),
            sentCount: Int(sentMessages),
            failedCount: Int(failedMessages),
            pendingCount: Int(pendingMessages),
            successRate: successRate,
            status: campaign.status ?? "unknown",
            dateCreated: campaign.dateCreated ?? Date(),
            dateSent: campaign.messages?.compactMap { ($0 as? Message)?.dateSent }.first
        )
    }

    func getOverallAnalytics() -> OverallAnalytics {
        let totalCampaigns = campaigns.count
        let completedCampaigns = campaigns.filter { $0.status == "completed" || $0.status == "completed_with_errors" }.count
        let totalMessagesSent = campaigns.reduce(0) { $0 + Int($1.sentCount) }
        let totalRecipients = campaigns.reduce(0) { $0 + Int($1.totalRecipients) }

        let averageSuccessRate = campaigns.isEmpty ? 0.0 : campaigns.reduce(0.0) { result, campaign in
            let rate = campaign.totalRecipients > 0 ? Double(campaign.sentCount) / Double(campaign.totalRecipients) * 100 : 0
            return result + rate
        } / Double(campaigns.count)

        return OverallAnalytics(
            totalCampaigns: totalCampaigns,
            completedCampaigns: completedCampaigns,
            totalMessagesSent: totalMessagesSent,
            totalRecipients: totalRecipients,
            averageSuccessRate: averageSuccessRate
        )
    }

    // MARK: - Data Loading

    private func loadCampaigns() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Campaign> = Campaign.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Campaign.dateCreated, ascending: false)]

        do {
            campaigns = try context.fetch(request)
        } catch {
            print("Error loading campaigns: \(error)")
        }
    }

    // MARK: - Utility Methods

    func getCampaignsByStatus(_ status: String) -> [Campaign] {
        return campaigns.filter { $0.status == status }
    }

    func getActiveCampaigns() -> [Campaign] {
        return campaigns.filter { $0.status == "sending" || $0.status == "scheduled" }
    }

    func getRecentCampaigns(limit: Int = 5) -> [Campaign] {
        return Array(campaigns.prefix(limit))
    }


    func generateMessagesForCampaign(_ campaign: Campaign) -> [(phone: String, body: String)] {
        guard let template = campaign.template else { return [] }

        // Collect unique contacts across target groups
        let allContacts = Set(campaign.targetGroupsArray.flatMap { $0.contactsArray })
        let messages: [(phone: String, body: String)] = allContacts.compactMap { contact in
            guard let phone = contact.phoneNumber, !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            let processedContent = templateManager.processTemplate(template, for: contact)
            return (phone: phone, body: processedContent)
        }

        return messages
    }

    /// Save campaign changes to Core Data
    func saveCampaign(_ campaign: Campaign) {
        do {
            try persistenceController.container.viewContext.save()
        } catch {
            print("Error saving campaign: \(error)")
        }
    }
}

// MARK: - Extensions

extension ContactGroup {
    var contactsArray: [Contact] {
        return contacts?.allObjects as? [Contact] ?? []
    }
}

extension Contact {
    var messagesArray: [Message] {
        return messages?.allObjects as? [Message] ?? []
    }
}

extension Campaign {
    var targetGroupsArray: [ContactGroup] {
        return targetGroups?.allObjects as? [ContactGroup] ?? []
    }

    var messagesArray: [Message] {
        return messages?.allObjects as? [Message] ?? []
    }
}


// MARK: - Data Models

enum AutomatedSendingMethod {
    case autoSend
    case batchProcessor(batchSize: Int, delaySeconds: Double)
}

struct CampaignAnalytics {
    let totalRecipients: Int
    let sentCount: Int
    let failedCount: Int
    let pendingCount: Int
    let successRate: Double
    let status: String
    let dateCreated: Date
    let dateSent: Date?
}

struct OverallAnalytics {
    let totalCampaigns: Int
    let completedCampaigns: Int
    let totalMessagesSent: Int
    let totalRecipients: Int
    let averageSuccessRate: Double
}

enum CampaignError: Error, LocalizedError {
    case noTemplate
    case noRecipients
    case noContacts
    case contextError
    case sendingFailed

    var errorDescription: String? {
        switch self {
        case .noTemplate:
            return "Campaign has no message template"
        case .noRecipients:
            return "Campaign has no recipients"
        case .noContacts:
            return "Campaign has no contacts to send to"
        case .contextError:
            return "Core Data context error"
        case .sendingFailed:
            return "Failed to send messages"
        }
    }
}
