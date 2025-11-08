//
//  FacebookAnalyticsService.swift
//  BulkMess
//
//  Created by Claude Code
//

import Foundation
import FacebookCore
import AppTrackingTransparency
import UIKit

/// Service for tracking app events and conversions with Facebook Analytics
class FacebookAnalyticsService {
    static let shared = FacebookAnalyticsService()

    private init() {}

    // MARK: - App Lifecycle Events

    /// Call this when the app finishes launching
    func activateApp() {
        AppEvents.shared.activateApp()
    }

    // MARK: - iOS 14.5+ App Tracking Transparency

    /// Request tracking permission
    /// Note: SDK v17+ automatically reads ATTrackingManager status
    @available(iOS 14, *)
    func requestTrackingPermission(completion: ((Bool) -> Void)? = nil) {
        // Verify we're on main thread
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.requestTrackingPermission(completion: completion)
            }
            return
        }

        // Check app state - ATT prompt only works when app is active
        let appState = UIApplication.shared.applicationState
        if appState != .active {
            // Wait for app to become active before showing ATT prompt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.requestTrackingPermission(completion: completion)
            }
            return
        }

        ATTrackingManager.requestTrackingAuthorization { status in
            let isAuthorized = status == .authorized
            DispatchQueue.main.async {
                completion?(isAuthorized)
            }
        }
    }

    // MARK: - Install & Onboarding Events

    /// Track when user completes onboarding
    func trackOnboardingCompleted() {
        AppEvents.shared.logEvent(.init("OnboardingCompleted"))
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
    }

    // MARK: - Engagement Events

    /// Track when user views analytics/dashboard
    func trackAnalyticsViewed() {
        AppEvents.shared.logEvent(.init("ViewAnalytics"))
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
    }

    // MARK: - Attribution & Deep Linking

    /// Handle Facebook App Links (for deep linking from ads)
    func handleAppLink(url: URL) {
        // Facebook SDK automatically handles app links
        // You can add custom handling here if needed
    }
}
