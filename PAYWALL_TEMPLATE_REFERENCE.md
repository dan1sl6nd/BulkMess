# Premium Paywall Template - Reference Implementation

This document provides a complete reference for implementing a high-converting iOS paywall with A/B testing, based on the BulkMess implementation.

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Complete Code Structure](#complete-code-structure)
4. [Design System](#design-system)
5. [A/B Testing Implementation](#ab-testing-implementation)
6. [Analytics Integration](#analytics-integration)
7. [Implementation Checklist](#implementation-checklist)
8. [Customization Guide](#customization-guide)

---

## Overview

### Paywall Features

✅ **A/B Testing**: Two variants (Cards vs Selector)
✅ **Responsive Layout**: Works on all iPhone sizes
✅ **Smooth Animations**: Glass morphism and modern effects
✅ **Social Proof**: Testimonials, ratings, FAQs
✅ **Dual Pricing Sections**: Primary (top) and secondary (bottom) for scrollers
✅ **Floating CTA**: Sticky purchase button with blur effect
✅ **Analytics Ready**: Track variant exposure, plan selection, purchases
✅ **StoreKit 2**: Modern in-app purchase integration
✅ **Legal Compliance**: Terms, Privacy, Auto-renewal disclosures

### Conversion Tactics

1. **Progressive Disclosure**: Benefits → Pricing → Social Proof → FAQ
2. **Anchoring**: Show original price crossed out with savings percentage
3. **Urgency**: Free trial and "Best Value" badges
4. **Social Proof**: Ratings, testimonials, user count
5. **Dual Pricing**: Catch users who scroll past first pricing section
6. **Clear CTA**: Floating button always visible with plan details

---

## Architecture

### File Structure

```
Views/
├── PaywallView.swift          # Main paywall container
├── PurchaseService.swift      # StoreKit 2 integration
└── AnalyticsService.swift     # Event tracking

UI/
└── DesignSystem.swift         # Theme and styling constants
```

### Component Hierarchy

```
PaywallView (Container)
├── ScrollView
│   ├── PaywallHeaderSection
│   ├── PaywallPricingSection (Primary - A/B tested)
│   ├── PaywallBenefitsSection
│   ├── PaywallSocialProofSection
│   ├── PaywallTestimonialsSection
│   ├── PaywallPricingSectionSecondary (Alternate variant)
│   └── PaywallFAQSection
└── FloatingPurchaseButton (safeAreaInset)
```

---

## Complete Code Structure

### 1. Main Paywall View

```swift
import SwiftUI
import StoreKit

struct PaywallView: View {
    @StateObject private var purchaseService = PurchaseService.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var lastAction: String? = nil
    @AppStorage("paywall_ab_variant") private var abVariantRaw: Int = -1

    enum ABVariant: Int {
        case cardsYearlyFirst = 0
        case selectorWeeklyFirst = 1
    }

    enum SubscriptionPlan: Hashable {
        case weekly
        case yearly
    }

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [AppTheme.primary, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // All sections here
                    PaywallHeaderSection()
                    PaywallPricingSection(selectedPlan: $selectedPlan, abVariant: ABVariant(rawValue: abVariantRaw) ?? .cardsYearlyFirst)
                    PaywallBenefitsSection()
                    PaywallSocialProofSection()
                    PaywallTestimonialsSection()
                    PaywallPricingSectionSecondary(selectedPlan: $selectedPlan, abVariant: ((ABVariant(rawValue: abVariantRaw) ?? .cardsYearlyFirst) == .cardsYearlyFirst) ? .selectorWeeklyFirst : .cardsYearlyFirst)
                    PaywallFAQSection()
                }
                .padding(.horizontal, 20)
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            FloatingPurchaseButton(
                selectedPlan: selectedPlan,
                purchaseService: purchaseService,
                variantName: (ABVariant(rawValue: abVariantRaw) == .selectorWeeklyFirst) ? "selector_weekly_first" : "cards_yearly_first",
                onPurchase: { lastAction = "purchase"; await purchase() },
                onRestore: { lastAction = "restore"; await restorePurchases() }
            )
        }
        .onAppear {
            if abVariantRaw == -1 {
                abVariantRaw = Int.random(in: 0...1)
            }
            // Analytics: Track variant exposure
            let variantName = (ABVariant(rawValue: abVariantRaw) == .selectorWeeklyFirst) ? "selector_weekly_first" : "cards_yearly_first"
            AnalyticsService.shared.track("paywall_variant_exposed", properties: ["variant": variantName])
        }
    }
}
```

### 2. Header Section

```swift
struct PaywallHeaderSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.md) {
                // App icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 110, height: 110)

                    Image(systemName: "message.circle.fill") // Replace with your icon
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }

                // Headline
                Text("Stop Sending Messages")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("One by One")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(AppTheme.accent)

                // Subheadline
                Text("Reach hundreds of contacts instantly with personalized bulk messaging and smart templates")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }
}
```

### 3. Pricing Section with A/B Testing

```swift
struct PaywallPricingSection: View {
    @Binding var selectedPlan: PaywallView.SubscriptionPlan
    let abVariant: PaywallView.ABVariant

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let variantName = (abVariant == .cardsYearlyFirst) ? "cards_yearly_first" : "selector_weekly_first"

            // Variant A: Cards, Yearly first
            if abVariant == .cardsYearlyFirst {
                VStack(spacing: AppTheme.Spacing.md) {
                    SimplePricingCard(
                        badge: "BEST VALUE",
                        badgeColor: AppTheme.success,
                        title: "Yearly Plan",
                        price: "$36.99/year",
                        originalPrice: "$119.88",
                        subtitle: "Save 69% • $3.08/month",
                        isSelected: selectedPlan == .yearly
                    )
                    .onTapGesture {
                        selectedPlan = .yearly
                        AnalyticsService.shared.track("paywall_plan_selected", properties: [
                            "plan": "yearly",
                            "variant": variantName,
                            "section": "primary"
                        ])
                    }

                    SimplePricingCard(
                        badge: "3 DAYS FREE",
                        badgeColor: AppTheme.accent,
                        title: "Weekly Plan",
                        price: "$9.99/week",
                        originalPrice: nil,
                        subtitle: "After 3-day free trial • Cancel anytime",
                        isSelected: selectedPlan == .weekly
                    )
                    .onTapGesture {
                        selectedPlan = .weekly
                        AnalyticsService.shared.track("paywall_plan_selected", properties: [
                            "plan": "weekly",
                            "variant": variantName,
                            "section": "primary"
                        ])
                    }
                }
            } else {
                // Variant B: Compact selector, Weekly first
                CompactPlanSelector(
                    selectedPlan: $selectedPlan,
                    order: [.weekly, .yearly],
                    context: "primary",
                    variantName: variantName
                )
                .glassCard(padding: AppTheme.Spacing.md)
            }
        }
    }
}
```

### 4. Pricing Card Component

```swift
struct SimplePricingCard: View {
    let badge: String
    let badgeColor: Color
    let title: String
    let price: String
    let originalPrice: String?
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Selection indicator
            Circle()
                .fill(isSelected ? AppTheme.accent : Color.clear)
                .stroke(isSelected ? AppTheme.accent : Color.white.opacity(0.3), lineWidth: 2)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 8, height: 8)
                        .opacity(isSelected ? 1 : 0)
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                // Badge
                HStack {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.sm)
                        .padding(.vertical, 3)
                        .background(badgeColor)
                        .cornerRadius(4)

                    Spacer()
                }

                // Title and price
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                        if let originalPrice = originalPrice {
                            Text(originalPrice)
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                                .strikethrough()
                        }

                        Text(price)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // Subtitle
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
                .stroke(isSelected ? AppTheme.accent : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
        )
    }
}
```

### 5. Compact Plan Selector (Alternative Layout)

```swift
struct CompactPlanSelector: View {
    @Binding var selectedPlan: PaywallView.SubscriptionPlan
    let order: [PaywallView.SubscriptionPlan]
    let context: String
    let variantName: String

    private func label(for plan: PaywallView.SubscriptionPlan) -> (title: String, subtitle: String, badge: String?) {
        switch plan {
        case .yearly:
            return ("Yearly", "$36.99/yr", nil)
        case .weekly:
            return ("Weekly", "$9.99/wk", "3 days free")
        }
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            ForEach(order, id: \.self) { plan in
                let isSelected = selectedPlan == plan
                let content = label(for: plan)

                Button(action: {
                    selectedPlan = plan
                    let planName = (plan == .weekly) ? "weekly" : "yearly"
                    AnalyticsService.shared.track("paywall_plan_selected", properties: [
                        "plan": planName,
                        "variant": variantName,
                        "section": context
                    ])
                }) {
                    VStack(spacing: AppTheme.Spacing.xs) {
                        if let badge = content.badge {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(AppTheme.accent)
                                .cornerRadius(4)
                        }
                        Text(content.title)
                            .font(.system(size: 14, weight: .semibold))
                        Text(content.subtitle)
                            .font(.system(size: 12, weight: .bold))
                            .opacity(1.0)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(
                        Capsule()
                            .fill(isSelected ? AppTheme.accent : Color.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .stroke(isSelected ? AppTheme.accent : Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
```

### 6. Benefits Section

```swift
struct PaywallBenefitsSection: View {
    private let columns = [GridItem(.flexible(), spacing: AppTheme.Spacing.lg), GridItem(.flexible(), spacing: AppTheme.Spacing.lg)]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Everything You Need")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.lg) {
                PaywallBenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Unlimited Contacts",
                    subtitle: "Add as many as you want"
                )
                PaywallBenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Custom Templates",
                    subtitle: "Personalized at scale"
                )
                PaywallBenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Bulk Campaigns",
                    subtitle: "Send to hundreds"
                )
                PaywallBenefitRow(
                    icon: "checkmark.circle.fill",
                    title: "Analytics",
                    subtitle: "Track engagement"
                )
            }
        }
        .glassCard(padding: AppTheme.Spacing.xl)
    }
}

struct PaywallBenefitRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.success)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }
}
```

### 7. Social Proof Section

```swift
struct PaywallSocialProofSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Rating section
            VStack(spacing: AppTheme.Spacing.sm) {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundColor(AppTheme.warning)
                            .font(.system(size: 16))
                    }
                }

                Text("4.9")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                Text("average rating")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .glassCard(padding: AppTheme.Spacing.md)

            // Join users text
            Text("Join 10,000+ users enhancing their messaging workflow")
                .font(AppTheme.Typography.callout)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)
        }
    }
}
```

### 8. Testimonials Section

```swift
struct PaywallTestimonialsSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Success Stories")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: AppTheme.Spacing.sm) {
                TestimonialCard(
                    avatar: "👨‍💼",
                    name: "Sarah M.",
                    rating: 5,
                    text: "BulkMess has revolutionized my business communications. I can now reach hundreds of clients instantly!"
                )

                TestimonialCard(
                    avatar: "👩‍💻",
                    name: "Mike P.",
                    rating: 5,
                    text: "The automation features save me hours every week. Best messaging app I've ever used!"
                )

                TestimonialCard(
                    avatar: "👨‍🎓",
                    name: "Alex K.",
                    rating: 5,
                    text: "Perfect for coordinating events. The template system makes everything so much easier."
                )
            }
        }
    }
}

struct TestimonialCard: View {
    let avatar: String
    let name: String
    let rating: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
            Text(avatar)
                .font(.system(size: 32))
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .italic()

                HStack {
                    Text(name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))

                    HStack(spacing: 2) {
                        ForEach(0..<rating, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundColor(AppTheme.warning)
                                .font(.system(size: 10))
                        }
                    }
                }
            }

            Spacer()
        }
        .glassCard(padding: AppTheme.Spacing.md)
    }
}
```

### 9. FAQ Section

```swift
struct PaywallFAQSection: View {
    @State private var expandedFAQ: Int? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Frequently Asked Questions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: AppTheme.Spacing.sm) {
                FAQItem(
                    question: "How does the free trial work?",
                    answer: "You get 3 days completely free with the weekly plan. Cancel anytime during the trial without being charged.",
                    isExpanded: expandedFAQ == 0
                ) {
                    expandedFAQ = expandedFAQ == 0 ? nil : 0
                }

                FAQItem(
                    question: "Can I cancel anytime?",
                    answer: "Yes, you can cancel your subscription at any time from your device settings. No questions asked.",
                    isExpanded: expandedFAQ == 1
                ) {
                    expandedFAQ = expandedFAQ == 1 ? nil : 1
                }

                FAQItem(
                    question: "Is my data secure?",
                    answer: "Absolutely. We use industry-standard encryption and never share your contact information with third parties.",
                    isExpanded: expandedFAQ == 2
                ) {
                    expandedFAQ = expandedFAQ == 2 ? nil : 2
                }
            }
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(question)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 12))
                }
                .padding()
            }

            if isExpanded {
                Text(answer)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal)
                    .padding(.bottom)
                    .multilineTextAlignment(.leading)
            }
        }
        .glassCard(padding: 0)
    }
}
```

### 10. Floating Purchase Button

```swift
struct FloatingPurchaseButton: View {
    let selectedPlan: PaywallView.SubscriptionPlan
    let purchaseService: PurchaseService
    let variantName: String
    let onPurchase: () async -> Void
    let onRestore: () async -> Void
    @Environment(\.openURL) private var openURL

    private var termsURL: URL {
        if let s = Bundle.main.object(forInfoDictionaryKey: "TERMS_URL") as? String, let u = URL(string: s) { return u }
        return URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    }

    private var privacyURL: URL {
        if let s = Bundle.main.object(forInfoDictionaryKey: "PRIVACY_URL") as? String, let u = URL(string: s) { return u }
        return URL(string: "https://www.apple.com/legal/privacy/")!
    }

    var body: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            // Main purchase button
            Button(action: {
                let planName = (selectedPlan == .weekly) ? "weekly" : "yearly"
                AnalyticsService.shared.track("paywall_cta_tapped", properties: [
                    "plan": planName,
                    "variant": variantName
                ])
                Task {
                    await onPurchase()
                }
            }) {
                HStack {
                    if case .loading = purchaseService.purchaseState {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        VStack(spacing: AppTheme.Spacing.xs) {
                            Text(selectedPlan == .weekly ? "$9.99/week" : "$36.99/year")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            Text(selectedPlan == .weekly ? "Start 3-Day Free Trial" : "Go Unlimited • Save 69%")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [AppTheme.accent, AppTheme.accentSecondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(28)
            }
            .disabled({
                if case .loading = purchaseService.purchaseState {
                    return true
                }
                return purchaseService.products.isEmpty
            }())

            // Footer links
            HStack(spacing: AppTheme.Spacing.lg) {
                Button("Terms of Use") { openURL(termsURL) }
                    .foregroundColor(.white.opacity(0.75))
                    .font(.system(size: 12))

                Button("Restore") {
                    AnalyticsService.shared.track("paywall_restore_tapped", properties: [
                        "variant": variantName
                    ])
                    Task {
                        await onRestore()
                    }
                }
                .foregroundColor(.white.opacity(0.75))
                .font(.system(size: 12))

                Button("Privacy Policy") { openURL(privacyURL) }
                    .foregroundColor(.white.opacity(0.75))
                    .font(.system(size: 12))

                Button("Manage") {
                    if let scene = UIApplication.shared.connectedScenes.first(where: { ($0 as? UIWindowScene)?.activationState == .foregroundActive }) as? UIWindowScene {
                        Task { try? await AppStore.showManageSubscriptions(in: scene) }
                    }
                }
                .foregroundColor(.white.opacity(0.75))
                .font(.system(size: 12))
            }

            Text("Auto‑renewing subscription. Cancel anytime in Settings.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.7))

            Text("Cancel at least 24 hours before the period ends to avoid renewal.")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, AppTheme.Spacing.lg)
        .background(
            ZStack(alignment: .top) {
                Color.clear
                    .background(.ultraThinMaterial)
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 0.5)
            }
        )
    }
}
```

---

## Design System

### Theme Constants

```swift
// DesignSystem.swift
enum AppTheme {
    // Colors
    static let primary = Color(hex: "#007AFF")
    static let accent = Color(hex: "#FF3B30")
    static let accentSecondary = Color(hex: "#FF6B62")
    static let success = Color(hex: "#34C759")
    static let warning = Color(hex: "#FF9500")
    static let error = Color(hex: "#FF3B30")
    static let background = Color(hex: "#F2F2F7")
    static let secondaryText = Color.gray

    // Typography
    enum Typography {
        static let headline = Font.system(size: 17, weight: .semibold)
        static let callout = Font.system(size: 16)
        static let caption = Font.system(size: 12)
    }

    // Spacing
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }
}

// Glass Card Modifier
extension View {
    func glassCard(padding: CGFloat) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

// Color from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

---

## A/B Testing Implementation

### Setup

1. **Store Variant in AppStorage**:
```swift
@AppStorage("paywall_ab_variant") private var abVariantRaw: Int = -1
```

2. **Assign Variant on First View**:
```swift
.onAppear {
    if abVariantRaw == -1 {
        abVariantRaw = Int.random(in: 0...1)
    }
}
```

3. **Track Variant Exposure**:
```swift
let variantName = (ABVariant(rawValue: abVariantRaw) == .selectorWeeklyFirst) ? "selector_weekly_first" : "cards_yearly_first"
AnalyticsService.shared.track("paywall_variant_exposed", properties: ["variant": variantName])
```

### Variants

**Variant A: Cards Layout (Yearly First)**
- Large card-based pricing
- Yearly plan shown first (best value)
- More visual hierarchy
- Better for showcasing savings

**Variant B: Selector Layout (Weekly First)**
- Compact toggle selector
- Weekly plan shown first (lower commitment)
- More minimal design
- Better for mobile-first users

### Analytics Events to Track

```
paywall_variant_exposed → {variant: "cards_yearly_first" | "selector_weekly_first"}
paywall_plan_selected → {plan: "weekly"|"yearly", variant: string, section: "primary"|"secondary"}
paywall_cta_tapped → {plan: "weekly"|"yearly", variant: string}
paywall_purchase_success → {plan: "weekly"|"yearly", variant: string}
paywall_purchase_failed → {plan: "weekly"|"yearly", variant: string, error: string}
paywall_restore_tapped → {variant: string}
```

---

## Analytics Integration

### Analytics Service (Minimal Implementation)

```swift
// AnalyticsService.swift
import Foundation

class AnalyticsService {
    static let shared = AnalyticsService()

    func track(_ event: String, properties: [String: Any] = [:]) {
        print("📊 Analytics: \(event)")
        print("   Properties: \(properties)")

        // Integrate with your analytics provider:
        // - Mixpanel: Mixpanel.mainInstance().track(event, properties: properties)
        // - Amplitude: Amplitude.instance().logEvent(event, withEventProperties: properties)
        // - Firebase: Analytics.logEvent(event, parameters: properties)
        // - PostHog: PostHog.shared.capture(event, properties: properties)
    }
}
```

### Key Metrics to Measure

1. **Conversion Rate**: `purchases / variant_exposures`
2. **Plan Selection**: `weekly_selections / yearly_selections`
3. **Scroll-through Rate**: `secondary_pricing_selections / total_selections`
4. **Time to Purchase**: Track time from exposure to purchase
5. **Variant Performance**: Compare conversion rates between variants

---

## Implementation Checklist

### Before Starting

- [ ] Set up StoreKit 2 with auto-renewable subscriptions
- [ ] Create subscription products in App Store Connect
- [ ] Add Privacy Policy and Terms of Use URLs to Info.plist
- [ ] Choose analytics provider (optional but recommended)

### Core Implementation

- [ ] Copy `PaywallView.swift` structure
- [ ] Implement `PurchaseService` with StoreKit 2
- [ ] Create `DesignSystem.swift` with theme constants
- [ ] Add all section components (Header, Pricing, Benefits, etc.)
- [ ] Implement `FloatingPurchaseButton` with legal disclosures
- [ ] Add A/B testing logic with `@AppStorage`

### Customization

- [ ] Replace app icon and colors
- [ ] Update headline and value proposition
- [ ] Customize pricing (replace $9.99/$36.99 with your prices)
- [ ] Update product IDs (replace `com.bulkmess.*` with yours)
- [ ] Write custom benefits (4-6 key features)
- [ ] Add relevant testimonials (3-5 reviews)
- [ ] Create app-specific FAQs (3-6 questions)
- [ ] Update Terms/Privacy URLs

### Testing

- [ ] Test both A/B variants
- [ ] Test purchase flow with sandbox accounts
- [ ] Test restore purchases
- [ ] Verify all links work (Terms, Privacy, Manage)
- [ ] Test on multiple screen sizes
- [ ] Verify legal disclosures are visible

### Analytics (Optional)

- [ ] Integrate analytics SDK
- [ ] Implement `AnalyticsService`
- [ ] Verify all tracking events fire
- [ ] Set up conversion funnel in analytics dashboard

---

## Customization Guide

### Step 1: Update Branding

Replace these in `PaywallHeaderSection`:
```swift
// Icon
Image(systemName: "YOUR_APP_ICON_NAME")

// Headlines
Text("Your Main Headline")
Text("Your Accent Text")
Text("Your value proposition in one compelling sentence")
```

### Step 2: Update Colors

In `DesignSystem.swift`:
```swift
static let primary = Color(hex: "#YOUR_PRIMARY_COLOR")
static let accent = Color(hex: "#YOUR_ACCENT_COLOR")
static let accentSecondary = Color(hex: "#YOUR_SECONDARY_COLOR")
```

### Step 3: Update Pricing

Replace throughout:
```swift
// Weekly plan
price: "$YOUR_WEEKLY_PRICE/week"

// Yearly plan
price: "$YOUR_YEARLY_PRICE/year"
originalPrice: "$YOUR_ORIGINAL_PRICE"
subtitle: "Save XX% • $X.XX/month"
```

### Step 4: Update Product IDs

In purchase function:
```swift
case .weekly:
    productToPurchase = purchaseService.products.first { $0.id == "com.yourapp.weekly" }
case .yearly:
    productToPurchase = purchaseService.products.first { $0.id == "com.yourapp.yearly" }
```

### Step 5: Update Benefits

In `PaywallBenefitsSection`:
```swift
PaywallBenefitRow(
    icon: "YOUR_SF_SYMBOL",
    title: "Your Benefit Title",
    subtitle: "Brief description"
)
```

### Step 6: Update Testimonials

In `PaywallTestimonialsSection`:
```swift
TestimonialCard(
    avatar: "👤", // Choose emoji or use image
    name: "Customer Name",
    rating: 5,
    text: "Your testimonial quote here"
)
```

### Step 7: Update FAQs

In `PaywallFAQSection`:
```swift
FAQItem(
    question: "Your question?",
    answer: "Your detailed answer.",
    isExpanded: expandedFAQ == INDEX
) {
    expandedFAQ = expandedFAQ == INDEX ? nil : INDEX
}
```

---

## Purchase Service Implementation

### Minimal PurchaseService with StoreKit 2

```swift
import StoreKit
import Foundation

@MainActor
class PurchaseService: ObservableObject {
    static let shared = PurchaseService()

    @Published var products: [Product] = []
    @Published var purchaseState: PurchaseState = .idle
    @Published var isPurchased: Bool = false

    private var transactionListener: Task<Void, Error>?

    enum PurchaseState {
        case idle
        case loading
        case purchased
        case failed(Error)
        case restored
    }

    init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchaseStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    func loadProducts() async {
        do {
            let productIDs = [
                "com.yourapp.weekly",
                "com.yourapp.yearly"
            ]
            products = try await Product.products(for: productIDs)
        } catch {
            print("Failed to load products: \(error)")
        }
    }

    func purchase(_ product: Product) async {
        purchaseState = .loading

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchaseStatus()
                purchaseState = .purchased

            case .userCancelled:
                purchaseState = .idle

            case .pending:
                purchaseState = .idle

            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error)
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await updatePurchaseStatus()
            purchaseState = .restored
        } catch {
            purchaseState = .failed(error)
        }
    }

    private func updatePurchaseStatus() async {
        var validSubscription = false

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.productType == .autoRenewable && transaction.revocationDate == nil {
                    validSubscription = true
                    break
                }
            }
        }

        isPurchased = validSubscription
    }

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await self.updatePurchaseStatus()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum PurchaseError: Error {
    case failedVerification
}
```

---

## App Store Connect Setup

### 1. Create Subscription Products

**Weekly Plan**:
- Product ID: `com.yourapp.weekly`
- Duration: 1 Week
- Price: $9.99 (or your price)
- Free Trial: 3 days
- Display Name: "Weekly Plan"
- Description: "Weekly subscription with 3-day free trial"

**Yearly Plan**:
- Product ID: `com.yourapp.yearly`
- Duration: 1 Year
- Price: $36.99 (or your price)
- Free Trial: None (optional)
- Display Name: "Yearly Plan"
- Description: "Best value - yearly subscription"

### 2. Configure Info.plist

Add these keys:
```xml
<key>TERMS_URL</key>
<string>https://yourwebsite.com/terms.html</string>

<key>PRIVACY_URL</key>
<string>https://yourwebsite.com/privacy.html</string>
```

### 3. App Review Information

In App Store Connect, add review notes explaining:
- What features require subscription
- How to test (provide test account)
- Your privacy practices
- Legal compliance (terms prohibit spam if applicable)

---

## Best Practices

### 1. Design Principles

✅ **Progressive Disclosure**: Start with benefits, then pricing
✅ **Social Proof**: Show ratings and testimonials
✅ **Clear Value**: Highlight savings and unique features
✅ **Reduce Friction**: Minimize steps to purchase
✅ **Legal Compliance**: Clear auto-renewal disclosures

### 2. A/B Testing Guidelines

- Run each variant for **at least 2 weeks** before making decisions
- Ensure **minimum 100 conversions per variant** for statistical significance
- Test **one variable at a time** (price order, layout, copy, etc.)
- Use **consistent analytics** tracking across variants
- Calculate **confidence intervals** before declaring a winner

### 3. Optimization Tips

🎯 **Headline**: Focus on the pain point you solve
🎯 **Pricing**: Show original price crossed out with savings %
🎯 **CTA Button**: Always visible, shows plan price
🎯 **Free Trial**: Prominently display if available
🎯 **Testimonials**: Use real quotes with names/avatars
🎯 **FAQs**: Address common objections (cancellation, data security)

### 4. Legal Requirements

- ✅ Terms of Use link accessible
- ✅ Privacy Policy link accessible
- ✅ Auto-renewal disclosure
- ✅ Cancel anytime statement
- ✅ Price clearly displayed
- ✅ Subscription length clearly displayed
- ✅ Free trial terms clear (if applicable)

---

## Troubleshooting

### Products Not Loading

**Issue**: `products` array is empty

**Solutions**:
1. Verify product IDs match App Store Connect exactly
2. Ensure agreements are signed in App Store Connect
3. Wait 24 hours after creating products
4. Check StoreKit configuration file for testing

### Purchase Fails

**Issue**: Purchase completes but `isPurchased` stays false

**Solutions**:
1. Verify transaction verification logic
2. Check `updatePurchaseStatus()` implementation
3. Ensure `transaction.finish()` is called
4. Check for multiple subscription groups

### A/B Variant Not Changing

**Issue**: Always shows same variant

**Solutions**:
1. Delete app and reinstall to reset `@AppStorage`
2. Check `abVariantRaw` is being set to random value
3. Verify variant selection logic in `onAppear`

---

## Example Analytics Dashboard

### Key Metrics to Track

```
Paywall Performance by Variant:
┌─────────────────────┬──────────┬────────────┬─────────────┐
│ Variant             │ Views    │ Purchases  │ Conv. Rate  │
├─────────────────────┼──────────┼────────────┼─────────────┤
│ cards_yearly_first  │ 1,245    │ 87         │ 6.99%       │
│ selector_weekly_1st │ 1,198    │ 92         │ 7.68%       │
└─────────────────────┴──────────┴────────────┴─────────────┘

Plan Selection:
┌─────────┬──────────┬────────────┐
│ Plan    │ Selects  │ Percentage │
├─────────┼──────────┼────────────┤
│ Weekly  │ 95       │ 53.1%      │
│ Yearly  │ 84       │ 46.9%      │
└─────────┴──────────┴────────────┘

Revenue per User (RPU):
- Weekly: $9.99 × 95 = $949.05
- Yearly: $36.99 × 84 = $3,107.16
- Total: $4,056.21
- Average: $22.67 per conversion
```

---

## Next Steps

1. **Copy this entire reference** into your new project
2. **Search and replace** all instances of:
   - `BulkMess` → Your app name
   - `com.bulkmess` → Your bundle ID
   - `$9.99/$36.99` → Your prices
3. **Customize** headlines, benefits, testimonials
4. **Test** both A/B variants thoroughly
5. **Deploy** and start measuring conversions
6. **Iterate** based on analytics data

---

## Resources

- **StoreKit 2 Docs**: https://developer.apple.com/documentation/storekit
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/#subscriptions
- **Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/

---

**Generated from**: BulkMess Paywall Implementation (v1.1)
**Last Updated**: October 2025
**License**: Use freely in your own projects

---

Good luck with your paywall! 🚀
