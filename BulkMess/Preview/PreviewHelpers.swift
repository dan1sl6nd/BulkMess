import SwiftUI
import CoreData

// Centralized helpers to build a consistent preview environment
@MainActor
struct PreviewEnvironment {
    let pc: PersistenceController
    let ctx: NSManagedObjectContext
    let contactManager: ContactManager
    let templateManager: MessageTemplateManager
    let messagingService: MessagingService
    let campaignManager: CampaignManager
    let deliverySettings: DeliverySettings

    static func make(seed: ((NSManagedObjectContext) -> Void)? = nil) -> PreviewEnvironment {
        let pc = PersistenceController.preview
        let ctx = pc.container.viewContext

        // Allow caller to insert seed objects before managers load
        if let seed = seed {
            seed(ctx)
            try? ctx.save()
        }

        let templateManager = MessageTemplateManager(persistenceController: pc)
        let contactManager = ContactManager(persistenceController: pc)
        let messagingService = MessagingService()
        let deliverySettings = DeliverySettings()
        let campaignManager = CampaignManager(persistenceController: pc, templateManager: templateManager, messagingService: messagingService, deliverySettings: deliverySettings)

        return PreviewEnvironment(
            pc: pc,
            ctx: ctx,
            contactManager: contactManager,
            templateManager: templateManager,
            messagingService: messagingService,
            campaignManager: campaignManager,
            deliverySettings: deliverySettings,
        )
    }
}

enum PreviewSeed {
    @MainActor @discardableResult
    static func contact(
        _ ctx: NSManagedObjectContext,
        firstName: String,
        lastName: String,
        phone: String,
        email: String? = nil
    ) -> Contact {
        let c = Contact(context: ctx)
        c.firstName = firstName
        c.lastName = lastName
        c.phoneNumber = phone
        c.email = email
        c.dateCreated = Date()
        return c
    }

    @MainActor @discardableResult
    static func template(
        _ ctx: NSManagedObjectContext,
        name: String,
        content: String
    ) -> MessageTemplate {
        let t = MessageTemplate(context: ctx)
        t.name = name
        t.content = content
        t.dateCreated = Date()
        t.dateModified = Date()
        return t
    }

    @MainActor @discardableResult
    static func group(
        _ ctx: NSManagedObjectContext,
        name: String,
        colorHex: String,
        contacts: [Contact] = []
    ) -> ContactGroup {
        let g = ContactGroup(context: ctx)
        g.name = name
        g.colorHex = colorHex
        g.dateCreated = Date()
        contacts.forEach { g.addToContacts($0) }
        return g
    }
}
