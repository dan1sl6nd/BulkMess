import SwiftUI
import StoreKit
import UIKit

struct PaywallView: View {
    @StateObject private var purchaseService = PurchaseService.shared
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var showFloatingButton = false
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
            // Background with app colors
            LinearGradient(
                colors: [AppTheme.primary, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // 1. Headline Section
                    PaywallHeaderSection()

                    // 2. Pricing Table (primary)
                    PaywallPricingSection(selectedPlan: $selectedPlan, abVariant: ABVariant(rawValue: abVariantRaw) ?? .cardsYearlyFirst)

                    // 3. Benefits Section
                    PaywallBenefitsSection()

                    // 4. Social Proof Section
                    PaywallSocialProofSection()

                    // 5. Testimonials
                    PaywallTestimonialsSection()

                    // 6. Pricing (secondary, for scrollers) — always show the alternate style
                    PaywallPricingSectionSecondary(
                        selectedPlan: $selectedPlan,
                        abVariant: ((ABVariant(rawValue: abVariantRaw) ?? .cardsYearlyFirst) == .cardsYearlyFirst) ? .selectorWeeklyFirst : .cardsYearlyFirst
                    )

                    // 7. FAQ Section
                    PaywallFAQSection()

                    // Natural bottom padding; safeAreaInset will add CTA
                    Spacer(minLength: AppTheme.Spacing.lg)
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            if abVariantRaw == -1 {
                abVariantRaw = Int.random(in: 0...1)
            }
            // Align default selection with variant for consistency
            if ABVariant(rawValue: abVariantRaw) == .selectorWeeklyFirst {
                selectedPlan = .weekly
            } else {
                selectedPlan = .yearly
            }
            let variantName = (ABVariant(rawValue: abVariantRaw) == .selectorWeeklyFirst) ? "selector_weekly_first" : "cards_yearly_first"
            AnalyticsService.shared.track("paywall_variant_exposed", properties: ["variant": variantName])
        }
        .onChange(of: purchaseService.purchaseState) { _, state in
            switch state {
            case .failed(let error):
                errorMessage = error.localizedDescription
                showingError = true
                AnalyticsService.shared.track("paywall_purchase_failed", properties: [
                    "plan": selectedPlan == .weekly ? "weekly" : "yearly",
                    "action": lastAction ?? "unknown",
                    "error": error.localizedDescription
                ])
            case .purchased:
                AnalyticsService.shared.track("paywall_purchase_success", properties: [
                    "plan": selectedPlan == .weekly ? "weekly" : "yearly",
                    "action": lastAction ?? "unknown"
                ])
            default:
                break
            }
        }
    }

    private func purchase() async {
        // If no products are available (testing/development), simulate purchase
        if purchaseService.products.isEmpty {
            // For development/testing - simulate successful purchase
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                purchaseService.isPurchased = true
            }
            #else
            showingError = true
            errorMessage = "Products not available. Please check your App Store Connect configuration."
            #endif
            return
        }

        let productToPurchase: Product?

        switch selectedPlan {
        case .weekly:
            productToPurchase = purchaseService.products.first { $0.id == "com.bulkmess.weekly" }
        case .yearly:
            productToPurchase = purchaseService.products.first { $0.id == "com.bulkmess.yearly" }
        }

        guard let product = productToPurchase else {
            showingError = true
            errorMessage = "Selected product not available. Please try another plan."
            return
        }

        await purchaseService.purchase(product)
    }

    private func restorePurchases() async {
        await purchaseService.restorePurchases()
    }
}

struct PaywallFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }
}

struct SubscriptionPlanView: View {
    let title: String
    let originalPrice: String?
    let currentPrice: String
    let perDayPrice: String?
    let isSelected: Bool
    let hasFreeTrial: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                if let originalPrice = originalPrice {
                    HStack(spacing: 4) {
                        Text(originalPrice)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .strikethrough()
                        Text(currentPrice)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                } else {
                    Text(currentPrice)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if hasFreeTrial {
                    Text("FREE")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                } else if let perDayPrice = perDayPrice {
                    Text(perDayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    Text("per day")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                }

                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .fill(isSelected ? Color.red : Color.clear)
                    .frame(width: 20, height: 20)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 8, height: 8)
                            .opacity(isSelected ? 1 : 0)
                    )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.red : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct CustomToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.red : Color.gray)
                .frame(width: 44, height: 26)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 22, height: 22)
                        .offset(x: configuration.isOn ? 9 : -9)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

struct AppFunctionalityBackground: View {
    @State private var animateIcons = false

    var body: some View {
        ZStack {
            // Floating message bubbles and app icons
            ForEach(0..<15, id: \.self) { index in
                let icons = ["message.fill", "person.2.fill", "doc.text.fill", "chart.bar.fill", "megaphone.fill"]
                let icon = icons[index % icons.count]
                let colors: [Color] = [.red, .blue, .orange, .purple, .green]
                let color = colors[index % colors.count]

                Image(systemName: icon)
                    .font(.system(size: CGFloat.random(in: 16...32)))
                    .foregroundColor(color.opacity(0.3))
                    .position(
                        x: CGFloat.random(in: 50...350),
                        y: CGFloat.random(in: 50...150)
                    )
                    .scaleEffect(animateIcons ? CGFloat.random(in: 0.8...1.2) : 1)
                    .opacity(animateIcons ? Double.random(in: 0.2...0.6) : 0.4)
                    .animation(
                        Animation.easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...1)),
                        value: animateIcons
                    )
            }

            // Connection lines between elements
            Path { path in
                path.move(to: CGPoint(x: 50, y: 100))
                path.addLine(to: CGPoint(x: 200, y: 80))
                path.addLine(to: CGPoint(x: 350, y: 120))
            }
            .stroke(Color.white.opacity(0.1), lineWidth: 1)

            Path { path in
                path.move(to: CGPoint(x: 100, y: 50))
                path.addLine(to: CGPoint(x: 250, y: 150))
                path.addLine(to: CGPoint(x: 300, y: 60))
            }
            .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        }
        .onAppear {
            animateIcons = true
        }
    }
}

// MARK: - Paywall Sections

struct PaywallHeaderSection: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            // App icon and main headline
            VStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .frame(width: 110, height: 110)

                    Image(systemName: "message.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.white)
                }

                Text("Stop Sending Messages")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)

                Text("One by One")
                    .font(.system(size: 30, weight: .heavy))
                    .foregroundColor(AppTheme.accent)

                Text("Reach hundreds of contacts instantly with personalized bulk messaging and smart templates")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }
        }
    }
}

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
                        badge: "FREE TRIAL",
                        badgeColor: AppTheme.accent,
                        title: "Weekly Plan",
                        price: "3 days FREE",
                        originalPrice: nil,
                        subtitle: "Then $9.99/week • Cancel anytime",
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

// Secondary pricing section respects the same A/B styling
struct PaywallPricingSectionSecondary: View {
    @Binding var selectedPlan: PaywallView.SubscriptionPlan
    let abVariant: PaywallView.ABVariant

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            let variantName = (abVariant == .cardsYearlyFirst) ? "cards_yearly_first" : "selector_weekly_first"
            Text("Choose Your Plan")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            if abVariant == .cardsYearlyFirst {
                VStack(spacing: AppTheme.Spacing.sm) {
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
                            "section": "secondary"
                        ])
                    }
                    .scaleEffect(0.98)

                    SimplePricingCard(
                        badge: "FREE TRIAL",
                        badgeColor: AppTheme.accent,
                        title: "Weekly Plan",
                        price: "3 days FREE",
                        originalPrice: nil,
                        subtitle: "Then $9.99/week • Cancel anytime",
                        isSelected: selectedPlan == .weekly
                    )
                    .onTapGesture {
                        selectedPlan = .weekly
                        AnalyticsService.shared.track("paywall_plan_selected", properties: [
                            "plan": "weekly",
                            "variant": variantName,
                            "section": "secondary"
                        ])
                    }
                    .scaleEffect(0.98)
                }
            } else {
                CompactPlanSelector(
                    selectedPlan: $selectedPlan,
                    order: [.weekly, .yearly],
                    context: "secondary",
                    variantName: variantName
                )
                .glassCard(padding: AppTheme.Spacing.md)
            }
        }
    }
}

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

// Compact two-option selector for plans
struct CompactPlanSelector: View {
    @Binding var selectedPlan: PaywallView.SubscriptionPlan
    let order: [PaywallView.SubscriptionPlan]
    let context: String
    let variantName: String

    private func label(for plan: PaywallView.SubscriptionPlan) -> (title: String, subtitle: String) {
        switch plan {
        case .yearly:
            return ("Yearly", "$36.99/yr")
        case .weekly:
            return ("Weekly", "3 days free")
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
                        Text(content.title)
                            .font(.system(size: 14, weight: .semibold))
                        Text(content.subtitle)
                            .font(.system(size: 11))
                            .opacity(0.9)
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

struct PricingCard: View {
    let title: String
    let subtitle: String
    let originalPrice: String?
    let currentPrice: String
    let savings: String?
    let perMonth: String
    let isSelected: Bool
    let hasCheckmark: Bool

    var body: some View {
        VStack(spacing: 8) {
            // Title
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Savings badge
            if let savings = savings {
                Text(savings)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(savings == "TRY FREE" ? AppTheme.accent : AppTheme.success)
                    .cornerRadius(8)
            }

            // Prices
            VStack(spacing: 2) {
                if let originalPrice = originalPrice {
                    Text(originalPrice)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                        .strikethrough()
                }

                Text(currentPrice)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(perMonth)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Checkmark
            if hasCheckmark {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppTheme.accent)
                    .font(.system(size: 20))
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 2)
                    .frame(width: 20, height: 20)
            }
        }
        .frame(width: 140, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isSelected ? 0.2 : 0.1))
                .stroke(isSelected ? AppTheme.accent : Color.white.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}

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

                FAQItem(
                    question: "What happens after my trial ends?",
                    answer: "Your subscription will automatically start based on the plan you selected. You can cancel anytime from your device settings.",
                    isExpanded: expandedFAQ == 3
                ) {
                    expandedFAQ = expandedFAQ == 3 ? nil : 3
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
                            Text(selectedPlan == .weekly ? "Start Free Trial" : "Go Unlimited")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Text(selectedPlan == .weekly ? "3 days free, then $9.99/week" : "$36.99/year • Save 69%")
                                .font(.system(size: 12))
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

#Preview {
    PaywallView()
}
