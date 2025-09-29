import Foundation
import CoreData
import UserNotifications

class FollowUpService: ObservableObject {
    private let persistenceController: PersistenceController
    private let templateManager: MessageTemplateManager
    private let messagingService: MessagingService

    init(persistenceController: PersistenceController = .shared, templateManager: MessageTemplateManager, messagingService: MessagingService) {
        self.persistenceController = persistenceController
        self.templateManager = templateManager
        self.messagingService = messagingService
    }

    // MARK: - Follow-up Sequence Management

    func createFollowUpSequence(name: String, followUpMessages: [FollowUpMessageData]) -> FollowUpSequence {
        let context = persistenceController.container.viewContext

        let sequence = FollowUpSequence(context: context)
        sequence.name = name
        sequence.isActive = true

        for (index, followUpData) in followUpMessages.enumerated() {
            let followUpMessage = FollowUpMessage(context: context)
            followUpMessage.stepNumber = Int16(index + 1)
            followUpMessage.delayDays = Int16(followUpData.delayDays)
            followUpMessage.delayHours = Int16(followUpData.delayHours)
            followUpMessage.template = followUpData.template
            followUpMessage.sequence = sequence
        }

        do {
            try context.save()
            return sequence
        } catch {
            print("Error creating follow-up sequence: \(error)")
            return sequence
        }
    }

    func updateFollowUpSequence(_ sequence: FollowUpSequence, name: String, followUpMessages: [FollowUpMessageData]) {
        let context = persistenceController.container.viewContext

        sequence.name = name

        // Remove existing follow-up messages safely
        if let existingMessages = sequence.followUpMessages {
            for message in existingMessages {
                if let followUpMessage = message as? FollowUpMessage {
                    context.delete(followUpMessage)
                }
            }
        }

        // Add new follow-up messages
        for (index, followUpData) in followUpMessages.enumerated() {
            let followUpMessage = FollowUpMessage(context: context)
            followUpMessage.stepNumber = Int16(index + 1)
            followUpMessage.delayDays = Int16(followUpData.delayDays)
            followUpMessage.delayHours = Int16(followUpData.delayHours)
            followUpMessage.template = followUpData.template
            followUpMessage.sequence = sequence
        }

        do {
            try context.save()
        } catch {
            print("Error updating follow-up sequence: \(error)")
        }
    }

    func deleteFollowUpSequence(_ sequence: FollowUpSequence) {
        let context = persistenceController.container.viewContext
        context.delete(sequence)

        do {
            try context.save()
        } catch {
            print("Error deleting follow-up sequence: \(error)")
        }
    }

    // MARK: - Follow-up Execution

    func scheduleFollowUps(for campaign: Campaign) {
        // Store the ObjectID to safely pass to background thread
        let campaignObjectID = campaign.objectID

        // Use a background context for thread-safe Core Data operations
        let backgroundContext = persistenceController.container.newBackgroundContext()

        backgroundContext.perform {
            do {
                // Fetch the campaign in the background context
                guard let backgroundCampaign = try backgroundContext.existingObject(with: campaignObjectID) as? Campaign else {
                    print("❌ Could not fetch campaign in background context")
                    return
                }

                guard let followUpSequence = backgroundCampaign.followUpSequence,
                      followUpSequence.isActive else {
                    print("ℹ️ No active follow-up sequence for campaign")
                    return
                }

                print("📊 Follow-up sequence found: \(followUpSequence.name ?? "Unknown")")

                // Get all contacts from target groups
                let allContacts = Set(backgroundCampaign.targetGroupsArray.flatMap { $0.contactsArray })
                print("👥 Found \(allContacts.count) contacts for follow-ups")

                for contact in allContacts {
                    self.scheduleFollowUpsForContact(contact, campaign: backgroundCampaign, sequence: followUpSequence)
                }

                // Start monitoring for responses after campaign is sent
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.startMonitoringForCampaign(backgroundCampaign)
                }

                print("✅ Follow-up scheduling completed for \(allContacts.count) contacts")

            } catch {
                print("❌ Error in follow-up scheduling: \(error)")
            }
        }
    }

    private func scheduleSimpleFollowUpsForContact(_ contact: Contact, campaign: Campaign, sequence: FollowUpSequence) {
        guard let followUpMessages = sequence.followUpMessages?.allObjects as? [FollowUpMessage] else {
            print("❌ No follow-up messages found")
            return
        }

        let sortedMessages = followUpMessages.sorted { $0.stepNumber < $1.stepNumber }
        print("📅 Scheduling \(sortedMessages.count) follow-up messages for \(contact.firstName ?? "Unknown")")

        for followUpMessage in sortedMessages {
            let delayTimeInterval = TimeInterval(followUpMessage.delayDays * 24 * 3600 + followUpMessage.delayHours * 3600)
            let scheduledDate = Date().addingTimeInterval(delayTimeInterval)

            // Schedule simple local notification for follow-up
            let messageContent = followUpMessage.template?.content ?? "Follow-up message"
            self.scheduleSimpleFollowUpNotification(
                contactName: contact.firstName ?? "Contact",
                contactPhone: contact.phoneNumber ?? "",
                messageContent: messageContent,
                scheduledDate: scheduledDate,
                stepNumber: followUpMessage.stepNumber
            )
        }
    }

    private func scheduleSimpleFollowUpNotification(
        contactName: String,
        contactPhone: String,
        messageContent: String,
        scheduledDate: Date,
        stepNumber: Int16
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Follow-up Ready: \(contactName)"
        content.body = "Time to send follow-up #\(stepNumber): \(messageContent.prefix(50))..."
        content.sound = .default

        // Simple user info without Core Data objects
        content.userInfo = [
            "type": "simple_follow_up",
            "contactName": contactName,
            "contactPhone": contactPhone,
            "messageContent": messageContent,
            "stepNumber": stepNumber
        ]

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let identifier = "simple_followup_\(contactPhone)_\(stepNumber)_\(Int(scheduledDate.timeIntervalSince1970))"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling follow-up notification: \(error)")
            } else {
                print("✅ Scheduled follow-up for \(contactName) in \(Int(trigger.nextTriggerDate()?.timeIntervalSinceNow ?? 0)) seconds")
            }
        }
    }

    private func startMonitoringForCampaign(_ campaign: Campaign) {
        // Set up periodic checks for message receipts
        // In a real implementation, this could be more sophisticated
        print("Started monitoring for responses to campaign: \(campaign.name ?? "Unknown")")
    }

    private func scheduleFollowUpsForContact(_ contact: Contact, campaign: Campaign, sequence: FollowUpSequence) {
        guard let followUpMessages = sequence.followUpMessages?.allObjects as? [FollowUpMessage] else { return }

        let sortedMessages = followUpMessages.sorted { $0.stepNumber < $1.stepNumber }

        for followUpMessage in sortedMessages {
            let delayTimeInterval = TimeInterval(followUpMessage.delayDays * 24 * 3600 + followUpMessage.delayHours * 3600)
            let scheduledDate = Date().addingTimeInterval(delayTimeInterval)

            // Schedule local notification for follow-up
            scheduleFollowUpNotification(
                contact: contact,
                followUpMessage: followUpMessage,
                scheduledDate: scheduledDate,
                campaign: campaign
            )
        }
    }

    private func scheduleFollowUpNotification(
        contact: Contact,
        followUpMessage: FollowUpMessage,
        scheduledDate: Date,
        campaign: Campaign
    ) {
        let content = UNMutableNotificationContent()
        content.title = "Follow-up Message Ready"
        content.body = "Time to send follow-up message to \(getContactName(contact))"
        content.sound = .default

        // Add user info for handling the notification
        content.userInfo = [
            "type": "follow_up",
            "contactObjectID": contact.objectID.uriRepresentation().absoluteString,
            "followUpMessageObjectID": followUpMessage.objectID.uriRepresentation().absoluteString,
            "campaignObjectID": campaign.objectID.uriRepresentation().absoluteString,
            "contactPhone": contact.phoneNumber ?? ""
        ]



        content.categoryIdentifier = "FOLLOWUP_CATEGORY"

        // Register the category if not already registered
        setupNotificationCategories()

        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

        let identifier = "follow_up_\(contact.objectID.uriRepresentation().absoluteString)_\(followUpMessage.stepNumber)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling follow-up notification: \(error)")
            }
        }
    }

    private func setupNotificationCategories() {
        let sendAction = UNNotificationAction(
            identifier: "SEND_FOLLOWUP",
            title: "Send Now",
            options: [.foreground]
        )

        let respondedAction = UNNotificationAction(
            identifier: "MARK_RESPONDED",
            title: "They Responded",
            options: []
        )

        let cancelAction = UNNotificationAction(
            identifier: "CANCEL_FOLLOWUP",
            title: "Cancel",
            options: [.destructive]
        )

        let followUpCategory = UNNotificationCategory(
            identifier: "FOLLOWUP_CATEGORY",
            actions: [sendAction, respondedAction, cancelAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([followUpCategory])
    }

    // MARK: - Follow-up Execution

    func executeFollowUp(
        contact: Contact,
        followUpMessage: FollowUpMessage,
        campaign: Campaign,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let template = followUpMessage.template else {
            completion(.failure(FollowUpError.noTemplate))
            return
        }

        let processedContent = templateManager.processTemplate(template, for: contact)

        // Create message record
        let context = persistenceController.container.viewContext
        let message = Message(context: context)
        message.content = processedContent
        message.contact = contact
        message.campaign = campaign
        message.status = "pending"
        message.isFollowUp = true
        message.followUpStep = followUpMessage.stepNumber

        do {
            try context.save()
        } catch {
            completion(.failure(error))
            return
        }

        // Send the follow-up message
        messagingService.sendSingleMessage(
            to: contact.phoneNumber ?? "",
            content: processedContent
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    message.status = "sent"
                    message.dateSent = Date()
                    completion(.success(()))
                case .failure(let error):
                    message.status = "failed"
                    message.errorMessage = error.localizedDescription
                    completion(.failure(error))
                }

                try? context.save()
            }
        }
    }

    // MARK: - Notification Permissions

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }

    func checkNotificationPermission(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }

    // MARK: - Helper Methods

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

    // MARK: - Data Retrieval

    func getFollowUpSequences() -> [FollowUpSequence] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<FollowUpSequence> = FollowUpSequence.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \FollowUpSequence.name, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error loading follow-up sequences: \(error)")
            return []
        }
    }

    func getPendingFollowUps() -> [Message] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "isFollowUp == YES AND status == %@", "pending")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Message.dateSent, ascending: true)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error loading pending follow-ups: \(error)")
            return []
        }
    }

    // MARK: - Scheduled Follow-ups (Notifications)

    struct ScheduledFollowUp: Identifiable {
        let id = UUID()
        let identifier: String
        let scheduledDate: Date?
        let contact: Contact?
        let followUpMessage: FollowUpMessage?
        let campaign: Campaign?
    }

    func getScheduledFollowUps(completion: @escaping ([ScheduledFollowUp]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self = self else { completion([]); return }
            let context = self.persistenceController.container.viewContext
            let psc = context.persistentStoreCoordinator
            var items: [ScheduledFollowUp] = []

            for req in requests {
                let info = req.content.userInfo
                guard let type = info["type"] as? String, type == "follow_up" else { continue }

                func object<T: NSManagedObject>(_ key: String) -> T? {
                    guard let s = info[key] as? String, let url = URL(string: s), let id = psc?.managedObjectID(forURIRepresentation: url) else { return nil }
                    return try? context.existingObject(with: id) as? T
                }

                let contact: Contact? = object("contactObjectID")
                let msg: FollowUpMessage? = object("followUpMessageObjectID")
                let campaign: Campaign? = object("campaignObjectID")

                let item = ScheduledFollowUp(
                    identifier: req.identifier,
                    scheduledDate: (req.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate(),
                    contact: contact,
                    followUpMessage: msg,
                    campaign: campaign
                )
                items.append(item)
            }

            // Sort by scheduled date
            let sorted = items.sorted { (a, b) in
                switch (a.scheduledDate, b.scheduledDate) {
                case let (ad?, bd?): return ad < bd
                case (_?, nil): return true
                case (nil, _?): return false
                default: return a.identifier < b.identifier
                }
            }
            completion(sorted)
        }
    }

    func cancelScheduledFollowUp(identifier: String, completion: (() -> Void)? = nil) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        completion?()
    }

    func executeScheduledFollowUp(_ item: ScheduledFollowUp, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let contact = item.contact, let followUpMessage = item.followUpMessage, let campaign = item.campaign else {
            completion(.failure(FollowUpError.noSequence)); return
        }
        executeFollowUp(contact: contact, followUpMessage: followUpMessage, campaign: campaign) { result in
            // Remove notification after attempting
            self.cancelScheduledFollowUp(identifier: item.identifier)
            completion(result)
        }
    }

    // MARK: - Message Receipt Handling

    func recordIncomingMessage(from contact: Contact, content: String, receivedAt date: Date = Date()) {
        let context = persistenceController.container.viewContext

        let message = Message(context: context)
        message.content = content
        message.contact = contact
        message.isIncoming = true
        message.dateReceived = date
        message.status = "received"

        do {
            try context.save()

            // Cancel follow-ups for this contact
            cancelFollowUpsForContact(contact)

        } catch {
            print("Error recording incoming message: \(error)")
        }
    }

    func cancelFollowUpsForContact(_ contact: Contact) {
        // Get all scheduled follow-ups for this contact and cancel them
        getScheduledFollowUps { [weak self] scheduledFollowUps in
            guard let self = self else { return }

            let contactFollowUps = scheduledFollowUps.filter {
                $0.contact?.objectID == contact.objectID
            }

            let identifiers = contactFollowUps.map { $0.identifier }

            if !identifiers.isEmpty {
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
                print("Cancelled \(identifiers.count) follow-up(s) for contact: \(self.getContactName(contact))")
            }
        }
    }

    func cancelFollowUpsForCampaign(_ campaign: Campaign, afterDate date: Date) {
        // Cancel follow-ups for all contacts in a campaign if they received a message after the campaign was sent
        let allContacts = Set(campaign.targetGroupsArray.flatMap { $0.contactsArray })

        for contact in allContacts {
            // Check if contact has received any message after the specified date
            if hasReceivedMessageAfter(contact: contact, date: date) {
                cancelFollowUpsForContact(contact)
            }
        }
    }

    private func hasReceivedMessageAfter(contact: Contact, date: Date) -> Bool {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "contact == %@ AND isIncoming == YES AND dateReceived > %@", contact, date as NSDate)
        request.fetchLimit = 1

        do {
            let messages = try context.fetch(request)
            return !messages.isEmpty
        } catch {
            print("Error checking for received messages: \(error)")
            return false
        }
    }
}

// MARK: - Supporting Types

struct FollowUpMessageData {
    var template: MessageTemplate
    var delayDays: Int
    var delayHours: Int
}

enum FollowUpError: Error, LocalizedError {
    case noTemplate
    case noSequence
    case schedulingFailed

    var errorDescription: String? {
        switch self {
        case .noTemplate:
            return "No template found for follow-up message"
        case .noSequence:
            return "No follow-up sequence found"
        case .schedulingFailed:
            return "Failed to schedule follow-up"
        }
    }
}
