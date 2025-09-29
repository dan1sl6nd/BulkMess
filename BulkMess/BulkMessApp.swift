//
//  BulkMessApp.swift
//  BulkMess
//
//  Created by Daniil Mukashev on 13/09/2025.
//

import SwiftUI
import UserNotifications
import CoreData

@main
struct BulkMessApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var contactManager: ContactManager
    @StateObject private var templateManager: MessageTemplateManager
    @StateObject private var messagingService: MessagingService
    @StateObject private var campaignManager: CampaignManager
    @StateObject private var deliverySettings: DeliverySettings
    @StateObject private var messageMonitoringService: MessageMonitoringService
    @StateObject private var automatedMessagingService: AutomatedMessagingService
    @StateObject private var notificationHandler: NotificationCenterHandler
    @StateObject private var errorHandler = ErrorHandler()
    @StateObject private var purchaseService = PurchaseService.shared

    init() {
        // Create instances once and use them consistently
        let contactManager = ContactManager()
        let templateManager = MessageTemplateManager()
        let messagingService = MessagingService()
        let deliverySettings = DeliverySettings()
        let campaignManager = CampaignManager(templateManager: templateManager, messagingService: messagingService, deliverySettings: deliverySettings)
        let messageMonitoringService = MessageMonitoringService()
        let automatedMessagingService = AutomatedMessagingService()
        let notificationHandler = NotificationCenterHandler(persistenceController: persistenceController)

        // Initialize StateObjects with the same instances
        self._contactManager = StateObject(wrappedValue: contactManager)
        self._templateManager = StateObject(wrappedValue: templateManager)
        self._messagingService = StateObject(wrappedValue: messagingService)
        self._campaignManager = StateObject(wrappedValue: campaignManager)
        self._deliverySettings = StateObject(wrappedValue: deliverySettings)
        self._messageMonitoringService = StateObject(wrappedValue: messageMonitoringService)
        self._automatedMessagingService = StateObject(wrappedValue: automatedMessagingService)
        self._notificationHandler = StateObject(wrappedValue: notificationHandler)

        // Set up notifications delegate
        UNUserNotificationCenter.current().delegate = notificationHandler

        // Register services in container for dependency injection
        ServiceContainer.shared.registerDefaultServices(persistenceController: persistenceController)
        ServiceContainer.shared.register(MessageMonitoringService.self, service: messageMonitoringService)
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if purchaseService.isPurchased {
                    MainTabView()
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                        .environmentObject(contactManager)
                        .environmentObject(templateManager)
                        .environmentObject(messagingService)
                        .environmentObject(campaignManager)
                        .environmentObject(deliverySettings)
                        .environmentObject(messageMonitoringService)
                        .environmentObject(automatedMessagingService)
                        .environmentObject(errorHandler)
                        .handleErrors(with: errorHandler)
                } else {
                    PaywallView()
                }
            }
            .environmentObject(purchaseService)
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    // MARK: - URL Handling

    private func handleIncomingURL(_ url: URL) {
        print("🔗 Received URL: \(url.absoluteString)")
        // Handle BulkMess URL scheme for automated integrations
        if url.scheme == "bulkmess" {
            print("✅ BulkMess URL scheme detected")
            handleBulkMessURL(url)
        } else {
            print("❌ Unknown URL scheme: \(url.scheme ?? "nil")")
        }
    }

    private func handleBulkMessURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Failed to parse URL components")
            return
        }

        print("🎯 URL Host: \(url.host ?? "nil")")
        print("🔍 Query items: \(components.queryItems?.description ?? "none")")

        switch url.host {
        case "record-response":
            handleRecordResponse(components: components)
        case "check-responses":
            handleCheckResponses(components: components)
        case "campaign-completed":
            print("🎉 Campaign completion callback received!")
            handleCampaignCompleted(components: components)
        default:
            print("❌ Unknown BulkMess URL action: \(url.host ?? "none")")
        }
    }

    private func handleRecordResponse(components: URLComponents) {
        guard let phoneNumber = components.queryItems?.first(where: { $0.name == "phone" })?.value,
              let message = components.queryItems?.first(where: { $0.name == "message" })?.value else {
            print("Missing required parameters for record-response")
            return
        }

        messageMonitoringService.recordIncomingMessage(fromPhoneNumber: phoneNumber, content: message)
        print("Recorded response from \(phoneNumber): \(message)")
    }


    private func handleCheckResponses(components: URLComponents) {
        // Trigger a check for all active campaigns
        messageMonitoringService.checkAllActiveCampaigns()
        print("Checked responses for all active campaigns")
    }

    private func handleCampaignCompleted(components: URLComponents) {
        print("📊 Processing simplified campaign completion...")

        guard let campaignId = components.queryItems?.first(where: { $0.name == "campaignId" })?.value else {
            print("❌ Missing campaignId parameter")
            print("📝 Available parameters:")
            components.queryItems?.forEach { item in
                print("   - \(item.name): \(item.value ?? "nil")")
            }
            return
        }

        print("✅ Campaign completion data:")
        print("   - Campaign ID: \(campaignId)")

        // Ensure Core Data operations happen on main thread
        DispatchQueue.main.async {
            print("🔄 Starting Core Data operations on main thread...")

            let context = persistenceController.container.viewContext
            print("📊 Got Core Data context")

            do {
                print("🔍 Converting campaignId to URL...")
                // Convert campaignId string back to NSManagedObjectID
                guard let objectIDURL = URL(string: campaignId) else {
                    print("❌ Invalid URL format for campaignId: \(campaignId)")
                    return
                }
                print("✅ Created URL from campaignId")

                print("🔍 Getting persistent store coordinator...")
                guard let persistentStoreCoordinator = context.persistentStoreCoordinator else {
                    print("❌ No persistent store coordinator available")
                    return
                }
                print("✅ Got persistent store coordinator")

                print("🔍 Converting URL to NSManagedObjectID...")
                guard let objectID = persistentStoreCoordinator.managedObjectID(forURIRepresentation: objectIDURL) else {
                    print("❌ Failed to convert campaignId to NSManagedObjectID: \(campaignId)")
                    print("💡 This usually means the campaignId is not a valid Core Data URI")
                    return
                }
                print("✅ Got NSManagedObjectID")

                print("🔍 Fetching campaign object...")
                // Get the campaign object directly
                guard let campaign = try context.existingObject(with: objectID) as? Campaign else {
                    print("❌ Campaign object not found or not of correct type")
                    return
                }
                print("✅ Got campaign object: \(campaign.name ?? "Unknown")")

                print("🔄 Updating campaign status...")
                // Update campaign status and counts (assume all messages sent successfully)
                let totalMessages = Int32(campaign.totalRecipients)
                campaign.sentCount = totalMessages
                campaign.failedCount = 0
                campaign.status = "completed"
                print("✅ Updated campaign properties")

                print("🔄 Saving Core Data context...")
                // Save changes
                try context.save()
                print("✅ Saved Core Data context")


                print("✅ Campaign \(campaign.name ?? "Unknown") completed via Shortcuts: sent \(campaign.sentCount) messages")
            } catch {
                print("❌ Error updating campaign completion: \(error)")
            }
        }
    }


}
