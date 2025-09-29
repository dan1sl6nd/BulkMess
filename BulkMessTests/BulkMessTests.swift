import XCTest
@testable import BulkMess

final class BulkMessTests: XCTestCase {

    // Helper to create a fresh in-memory persistence stack per test
    func makeInMemory() -> PersistenceController { PersistenceController(inMemory: true) }

    @MainActor
    func test_template_processing_replaces_placeholders() throws {
        let pc = makeInMemory()
        let ctx = pc.container.viewContext

        // Seed contact and template
        let contact = Contact(context: ctx)
        contact.firstName = "Jane"
        contact.lastName = "Doe"
        contact.phoneNumber = "+15551234567"
        contact.email = "jane@example.com"

        let template = MessageTemplate(context: ctx)
        template.name = "Greeting"
        template.content = "Hello {{fullName}} ({{firstName}} {{lastName}}) on {{currentDate}} at {{currentTime}}. Call: {{phoneNumber}} Email: {{email}}"

        try ctx.save()

        let manager = MessageTemplateManager(persistenceController: pc)

        // Build expected values using the same formatters the code uses
        let df = DateFormatter(); df.dateStyle = .medium
        let tf = DateFormatter(); tf.timeStyle = .short
        let expectedDate = df.string(from: Date())
        let expectedTime = tf.string(from: Date())

        let processed = manager.processTemplate(template, for: contact)

        XCTAssertTrue(processed.contains("Hello Jane Doe (Jane Doe) on \(expectedDate) at \(expectedTime)."))
        XCTAssertTrue(processed.contains("Call: +15551234567"))
        XCTAssertTrue(processed.contains("Email: jane@example.com"))
    }

    @MainActor
    func test_campaign_analytics_computes_counts_and_rate() throws {
        let pc = makeInMemory()
        let ctx = pc.container.viewContext

        // Seed template and contacts/group
        let template = MessageTemplate(context: ctx)
        template.name = "Notify"
        template.content = "Hi {{firstName}}"

        let g = ContactGroup(context: ctx)
        g.name = "VIP"
        g.colorHex = "#007AFF"

        for i in 1...4 {
            let c = Contact(context: ctx)
            c.firstName = "User\(i)"
            c.lastName = "Test"
            c.phoneNumber = "+1555000\(i)"
            g.addToContacts(c)
        }

        try ctx.save()

        let templateManager = MessageTemplateManager(persistenceController: pc)
        let messaging = MessagingService()
        let delivery = DeliverySettings()
        let follow = FollowUpService(persistenceController: pc, templateManager: templateManager, messagingService: messaging)
        let campaignManager = CampaignManager(persistenceController: pc, templateManager: templateManager, messagingService: messaging, deliverySettings: delivery, followUpService: follow)

        let campaign = campaignManager.createCampaign(name: "Alpha", template: template, targetGroups: [g])
        // Simulate results
        campaign.sentCount = 3
        campaign.failedCount = 1
        campaign.status = "completed"

        let analytics = campaignManager.getCampaignAnalytics(campaign)

        XCTAssertEqual(analytics.totalRecipients, 4)
        XCTAssertEqual(analytics.sentCount, 3)
        XCTAssertEqual(analytics.failedCount, 1)
        XCTAssertEqual(analytics.pendingCount, 0)
        XCTAssertEqual(analytics.status, "completed")
        XCTAssertEqual(analytics.successRate, 75.0, accuracy: 0.0001)
    }
}
