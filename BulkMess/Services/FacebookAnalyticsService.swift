//
//  FacebookAnalyticsService.swift
//  BulkMess
//
//  Created by Claude Code
//

import Foundation
import FacebookCore
import AppTrackingTransparency

/// Service for tracking app events and conversions with Facebook Analytics
class FacebookAnalyticsService {
    static let shared = FacebookAnalyticsService()

    private init() {}

    // MARK: - App Lifecycle Events

    /// Call this when the app finishes launching
    func activateApp() {
        AppEvents.shared.activateApp()
        print("📊 Facebook: App activated")

        // Log tracking status (SDK v17+ handles this automatically)
        logTrackingStatus()
    }

    // MARK: - iOS 14.5+ App Tracking Transparency

    /// Request tracking permission
    /// Note: SDK v17+ automatically reads ATTrackingManager status
    @available(iOS 14, *)
    func requestTrackingPermission(completion: ((Bool) -> Void)? = nil) {
        // Log environment info
        #if targetEnvironment(simulator)
        print("⚠️ Facebook: Running on SIMULATOR - ATT prompts may not work properly")
        print("   For proper ATT testing, use a REAL DEVICE with iOS 14.5+")
        #else
        print("✅ Facebook: Running on REAL DEVICE")
        #endif

        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        print("📱 Facebook: iOS Version: \(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)")

        if osVersion.majorVersion < 14 || (osVersion.majorVersion == 14 && osVersion.minorVersion < 5) {
            print("⚠️ Facebook: ATT requires iOS 14.5+, you have iOS \(osVersion.majorVersion).\(osVersion.minorVersion)")
        }

        // Log current status before requesting
        let currentStatus = ATTrackingManager.trackingAuthorizationStatus
        let statusString = attStatusToString(currentStatus)
        print("📊 Facebook: Current ATT status before request: \(statusString)")

        ATTrackingManager.requestTrackingAuthorization { status in
            let isAuthorized = status == .authorized
            let newStatusString = self.attStatusToString(status)

            DispatchQueue.main.async {
                print("📊 Facebook: ATT status after request: \(newStatusString)")
                print("📊 Facebook: Tracking permission - \(isAuthorized ? "Granted" : "Denied")")

                if status == currentStatus && status != .authorized {
                    print("⚠️ Facebook: ATT status unchanged - popup may not have shown")
                    print("   Check: Settings → Privacy & Security → Tracking → Allow Apps to Request to Track")
                }

                completion?(isAuthorized)
            }
        }
    }

    @available(iOS 14, *)
    private func attStatusToString(_ status: ATTrackingManager.AuthorizationStatus) -> String {
        switch status {
        case .notDetermined:
            return "notDetermined (user hasn't been asked yet)"
        case .restricted:
            return "restricted (system-wide tracking disabled or parental controls)"
        case .denied:
            return "denied (user denied or system setting is OFF)"
        case .authorized:
            return "authorized (user granted permission)"
        @unknown default:
            return "unknown"
        }
    }

    /// Log current tracking authorization status
    /// SDK v17+ automatically uses ATTrackingManager.trackingAuthorizationStatus
    private func logTrackingStatus() {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            let isEnabled = status == .authorized
            print("📊 Facebook: Advertiser tracking enabled - \(isEnabled)")
        } else {
            // iOS 13 and below - tracking is always enabled
            print("📊 Facebook: Advertiser tracking enabled - true")
        }
    }

    // MARK: - Install & Onboarding Events

    /// Track when user completes onboarding
    func trackOnboardingCompleted() {
        AppEvents.shared.logEvent(.init("OnboardingCompleted"))
        print("📊 Facebook: Onboarding completed")
    }

    // MARK: - Subscription Events

    /// Track when user starts free trial
    func trackTrialStarted(plan: String, value: Double) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .content: plan,
            .currency: "USD"
        ]

        AppEvents.shared.logEvent(
            .init("StartTrial"),
            valueToSum: value,
            parameters: parameters
        )
        print("📊 Facebook: Trial started - \(plan) ($\(String(format: "%.2f", value)))")
    }

    /// Track when user subscribes (converts from trial or direct purchase)
    func trackSubscriptionPurchase(plan: String, amount: Double, currency: String = "USD") {
        let parameters: [AppEvents.ParameterName: Any] = [
            .content: plan,
            .currency: currency
        ]

        AppEvents.shared.logPurchase(
            amount: amount,
            currency: currency,
            parameters: parameters
        )
        print("📊 Facebook: Purchase tracked - \(plan) ($\(String(format: "%.2f", amount)))")
    }

    /// Track when user cancels subscription
    func trackSubscriptionCancelled(plan: String) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .content: plan
        ]

        AppEvents.shared.logEvent(
            .init("SubscriptionCancelled"),
            parameters: parameters
        )
        print("📊 Facebook: Subscription cancelled - \(plan)")
    }

    // MARK: - Campaign Events

    /// Track when user creates a campaign
    func trackCampaignCreated(recipientCount: Int, hasTemplate: Bool) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .numItems: recipientCount,
            .content: hasTemplate ? "with_template" : "without_template"
        ]

        AppEvents.shared.logEvent(
            .init("CampaignCreated"),
            parameters: parameters
        )
        print("📊 Facebook: Campaign created - \(recipientCount) recipients")
    }

    /// Track when campaign is sent
    func trackCampaignSent(recipientCount: Int, messagesSent: Int) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .numItems: recipientCount,
            .success: messagesSent
        ]

        AppEvents.shared.logEvent(
            .init("CampaignSent"),
            parameters: parameters
        )
        print("📊 Facebook: Campaign sent - \(messagesSent) messages")
    }

    /// Track when campaign completes
    func trackCampaignCompleted(recipientCount: Int, successRate: Double) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .numItems: recipientCount,
            .success: Int(successRate * 100)
        ]

        AppEvents.shared.logEvent(
            .init("CampaignCompleted"),
            valueToSum: Double(recipientCount),
            parameters: parameters
        )
        print("📊 Facebook: Campaign completed - \(Int(successRate * 100))% success rate")
    }

    // MARK: - Template Events

    /// Track when user creates a template
    func trackTemplateCreated(hasPersonalization: Bool) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .content: hasPersonalization ? "personalized" : "standard"
        ]

        AppEvents.shared.logEvent(
            .init("TemplateCreated"),
            parameters: parameters
        )
        print("📊 Facebook: Template created")
    }

    // MARK: - Contact Events

    /// Track when user adds contacts
    func trackContactsAdded(count: Int, source: String) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .numItems: count,
            .content: source // "manual", "import", "contacts_app"
        ]

        AppEvents.shared.logEvent(
            .init("ContactsAdded"),
            valueToSum: Double(count),
            parameters: parameters
        )
        print("📊 Facebook: Contacts added - \(count) from \(source)")
    }

    /// Track when user creates contact group
    func trackContactGroupCreated(contactCount: Int) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .numItems: contactCount
        ]

        AppEvents.shared.logEvent(
            .init("ContactGroupCreated"),
            parameters: parameters
        )
        print("📊 Facebook: Contact group created - \(contactCount) contacts")
    }

    // MARK: - Engagement Events

    /// Track when user views analytics/dashboard
    func trackAnalyticsViewed() {
        AppEvents.shared.logEvent(.init("ViewAnalytics"))
        print("📊 Facebook: Analytics viewed")
    }

    /// Track when user schedules a campaign
    func trackCampaignScheduled(hoursAhead: Int) {
        let parameters: [AppEvents.ParameterName: Any] = [
            .content: "\(hoursAhead)_hours"
        ]

        AppEvents.shared.logEvent(
            .init("CampaignScheduled"),
            parameters: parameters
        )
        print("📊 Facebook: Campaign scheduled - \(hoursAhead) hours ahead")
    }

    // MARK: - Custom Conversion Events

    /// Track custom event for Facebook Ads optimization
    func trackCustomEvent(name: String, parameters: [String: Any]? = nil) {
        var fbParameters: [AppEvents.ParameterName: Any] = [:]

        if let params = parameters {
            for (key, value) in params {
                fbParameters[AppEvents.ParameterName(rawValue: key)] = value
            }
        }

        AppEvents.shared.logEvent(
            .init(name),
            parameters: fbParameters
        )
        print("📊 Facebook: Custom event - \(name)")
    }

    // MARK: - Attribution & Deep Linking

    /// Handle Facebook App Links (for deep linking from ads)
    func handleAppLink(url: URL) {
        // Facebook SDK automatically handles app links
        // You can add custom handling here if needed
        print("📊 Facebook: App link received - \(url.absoluteString)")
    }
}
