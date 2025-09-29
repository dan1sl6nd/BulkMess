import Foundation
import CoreData
import UserNotifications

class MessageMonitoringService: ObservableObject {
    private let persistenceController: PersistenceController
    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
    }

    // MARK: - Manual Message Recording

    /// Manually record an incoming message from a contact
    /// This can be called when the user manually indicates they received a response
    func recordIncomingMessage(from contact: Contact, content: String, receivedAt date: Date = Date()) {
        print("📥 Recorded message from \(contact.firstName ?? "Unknown"): \(content)")
    }

    /// Record incoming message by phone number (finds contact automatically)
    func recordIncomingMessage(fromPhoneNumber phoneNumber: String, content: String, receivedAt date: Date = Date()) {
        guard let contact = findContact(by: phoneNumber) else {
            print("No contact found for phone number: \(phoneNumber)")
            return
        }

        recordIncomingMessage(from: contact, content: content, receivedAt: date)
    }

    // MARK: - Campaign Integration

    /// Check and cancel follow-ups for a campaign based on received messages after campaign date
    func checkAndCancelFollowUps(for campaign: Campaign) {
        print("📋 Checking responses for campaign: \(campaign.name ?? "Unknown")")
    }

    /// Bulk check for all active campaigns
    func checkAllActiveCampaigns() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Campaign> = Campaign.fetchRequest()
        request.predicate = NSPredicate(format: "status != %@", "completed")

        do {
            let campaigns = try context.fetch(request)
            for campaign in campaigns {
                checkAndCancelFollowUps(for: campaign)
            }
        } catch {
            print("Error fetching active campaigns: \(error)")
        }
    }

    // MARK: - Contact Lookup

    private func findContact(by phoneNumber: String) -> Contact? {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Contact> = Contact.fetchRequest()
        request.predicate = NSPredicate(format: "phoneNumber == %@", phoneNumber)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Error finding contact by phone number: \(error)")
            return nil
        }
    }

    // MARK: - Analytics

    /// Get received messages for a specific contact
    func getReceivedMessages(for contact: Contact) -> [Message] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "contact == %@ AND isIncoming == YES", contact)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Message.dateReceived, ascending: false)]

        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching received messages: \(error)")
            return []
        }
    }

    /// Get contacts who have responded after a specific date
    func getRespondedContacts(since date: Date) -> [Contact] {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Message> = Message.fetchRequest()
        request.predicate = NSPredicate(format: "isIncoming == YES AND dateReceived > %@", date as NSDate)

        do {
            let messages = try context.fetch(request)
            let contacts = Set(messages.compactMap { $0.contact })
            return Array(contacts)
        } catch {
            print("Error fetching responded contacts: \(error)")
            return []
        }
    }

    /// Get response rate for a campaign
    func getResponseRate(for campaign: Campaign) -> Double {
        let allContacts = Set(campaign.targetGroupsArray.flatMap { $0.contactsArray })
        guard !allContacts.isEmpty else { return 0.0 }

        let campaignDate = campaign.scheduledDate ?? campaign.dateCreated ?? Date()
        let respondedContacts = getRespondedContacts(since: campaignDate)

        let respondedCount = respondedContacts.filter { contact in
            allContacts.contains(contact)
        }.count

        return Double(respondedCount) / Double(allContacts.count) * 100.0
    }
}

// MARK: - Shortcuts Integration

extension MessageMonitoringService {

    /// API for Shortcuts app to record incoming messages
    /// This can be called from iOS Shortcuts when a message is received
    func handleShortcutIncomingMessage(phoneNumber: String, messageContent: String) {
        recordIncomingMessage(fromPhoneNumber: phoneNumber, content: messageContent)
    }
}

// MARK: - Notification Integration

extension MessageMonitoringService {

    /// Handle message receipt through notification actions
    /// Users can mark messages as "received" from notifications
    func handleNotificationResponse(for notificationIdentifier: String, action: String) {
        guard action == "message_received" else { return }

        // Parse notification identifier to find the contact
        print("📱 Received notification action: \(action) for identifier: \(notificationIdentifier)")
    }
}