import SwiftUI

// MARK: - Onboarding Answers Storage

class OnboardingAnswers: ObservableObject {
    static let shared = OnboardingAnswers()

    @Published var answers: [String: String] {
        didSet {
            save()
        }
    }

    private let storageKey = "onboardingAnswers"

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            self.answers = decoded
        } else {
            self.answers = [:]
        }
    }

    func save() {
        if let encoded = try? JSONEncoder().encode(answers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }

    var hasAnswers: Bool {
        return !answers.isEmpty
    }
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showIntro = true
    @State private var currentQuestion = 0
    @State private var answers: [String: String] = [:]
    @State private var showProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var showPaywall = false

    private let questions: [OnboardingQuestion] = [
        OnboardingQuestion(
            id: "audience",
            title: "Who do you message?",
            subtitle: "Help us understand your audience",
            icon: "person.2.fill",
            options: [
                OnboardingOption(id: "business", title: "Business Clients", icon: "briefcase.fill", color: .blue),
                OnboardingOption(id: "events", title: "Event Attendees", icon: "calendar.badge.clock", color: .orange),
                OnboardingOption(id: "community", title: "Community Members", icon: "person.3.fill", color: .green),
                OnboardingOption(id: "personal", title: "Friends & Family", icon: "heart.fill", color: .pink)
            ]
        ),
        OnboardingQuestion(
            id: "volume",
            title: "How many contacts?",
            subtitle: "What's your typical group size?",
            icon: "person.2.badge.gearshape.fill",
            options: [
                OnboardingOption(id: "few", title: "Just a few", subtitle: "< 10 contacts", icon: "person.fill", color: .gray),
                OnboardingOption(id: "dozens", title: "Dozens", subtitle: "10-50 contacts", icon: "person.2.fill", color: .blue),
                OnboardingOption(id: "hundreds", title: "Hundreds", subtitle: "50-200 contacts", icon: "person.3.fill", color: .orange),
                OnboardingOption(id: "thousands", title: "Thousands", subtitle: "200+ contacts", icon: "building.2.fill", color: .red)
            ]
        ),
        OnboardingQuestion(
            id: "goal",
            title: "What's your main goal?",
            subtitle: "What do you want to achieve?",
            icon: "target",
            options: [
                OnboardingOption(id: "marketing", title: "Marketing & Promotions", icon: "megaphone.fill", color: .purple),
                OnboardingOption(id: "events", title: "Event Coordination", icon: "calendar.badge.checkmark", color: .orange),
                OnboardingOption(id: "team", title: "Team Communication", icon: "person.3.sequence.fill", color: .blue),
                OnboardingOption(id: "updates", title: "Community Updates", icon: "bell.badge.fill", color: .green)
            ]
        ),
        OnboardingQuestion(
            id: "challenge",
            title: "What's your biggest challenge?",
            subtitle: "How can we help you most?",
            icon: "exclamationmark.triangle.fill",
            options: [
                OnboardingOption(id: "time", title: "Takes Too Much Time", icon: "clock.fill", color: .red),
                OnboardingOption(id: "personalize", title: "Hard to Personalize", icon: "person.crop.circle.badge.exclamationmark", color: .orange),
                OnboardingOption(id: "templates", title: "No Message Templates", icon: "doc.text.fill", color: .blue),
                OnboardingOption(id: "tracking", title: "Poor Tracking", icon: "chart.bar.fill", color: .purple)
            ]
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [AppTheme.primary, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if showIntro {
                IntroScreen {
                    withAnimation {
                        showIntro = false
                    }
                }
            } else if showProcessing {
                ProcessingScreen(progress: processingProgress, answers: answers)
            } else if showPaywall {
                PersonalizedPaywallView(answers: answers)
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    // Progress bar
                    ProgressView(value: Double(currentQuestion), total: Double(questions.count))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.md)

                    // Question counter
                    Text("\(currentQuestion + 1) of \(questions.count)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, AppTheme.Spacing.sm)

                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.xl) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 100, height: 100)

                                Image(systemName: questions[currentQuestion].icon)
                                    .font(.system(size: 44))
                                    .foregroundColor(.white)
                            }
                            .padding(.top, AppTheme.Spacing.xxl)

                            // Question
                            VStack(spacing: AppTheme.Spacing.sm) {
                                Text(questions[currentQuestion].title)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)

                                Text(questions[currentQuestion].subtitle)
                                    .font(AppTheme.Typography.callout)
                                    .foregroundColor(.white.opacity(0.8))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)

                            // Options
                            VStack(spacing: AppTheme.Spacing.md) {
                                ForEach(questions[currentQuestion].options) { option in
                                    OnboardingOptionCard(
                                        option: option,
                                        isSelected: answers[questions[currentQuestion].id] == option.id
                                    ) {
                                        selectOption(option)
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.bottom, AppTheme.Spacing.xxl)
                        }
                    }
                }
                .transition(.opacity)
            }
        }
    }

    private func selectOption(_ option: OnboardingOption) {
        // Track answer
        answers[questions[currentQuestion].id] = option.id

        // Analytics
        AnalyticsService.shared.track("onboarding_answer", properties: [
            "question": questions[currentQuestion].id,
            "answer": option.id,
            "step": "\(currentQuestion + 1)"
        ])

        // Move to next question or show processing
        guard !showProcessing else { return }

        let isLastQuestion = currentQuestion >= questions.count - 1

        DispatchQueue.main.async {
            if isLastQuestion {
                // Completed all questions - save answers and show processing immediately
                AnalyticsService.shared.track("onboarding_completed", properties: answers)
                OnboardingAnswers.shared.answers = answers

                withAnimation(.easeInOut(duration: 0.2)) {
                    showProcessing = true
                    processingProgress = 0
                }

                animateProcessing()
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    currentQuestion += 1
                }
            }
        }
    }

    private func animateProcessing() {
        let totalDuration: Double = 2.5
        let updateInterval: Double = 0.016 // ~60fps
        let totalSteps = Int(totalDuration / updateInterval)

        var currentStep = 0

        let timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { timer in
            currentStep += 1
            let progress = min(Double(currentStep) / Double(totalSteps), 1.0)

            withAnimation(.linear(duration: updateInterval)) {
                processingProgress = progress
            }

            if progress >= 1.0 {
                timer.invalidate()

                // Show paywall after processing completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation {
                        showProcessing = false
                        showPaywall = true
                    }
                }
            }
        }

        RunLoop.main.add(timer, forMode: .common)
    }
}

// MARK: - Intro Screen

struct IntroScreen: View {
    let onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()

            // App Icon/Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.accent.opacity(0.3), AppTheme.accentSecondary.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "megaphone.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }

            // Welcome Text
            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Welcome to BulkMess")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Let's personalize your experience")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)

                Text("Answer a few quick questions so we can tailor BulkMess to your needs")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .padding(.top, AppTheme.Spacing.sm)
            }

            Spacer()

            // Get Started Button
            Button(action: onGetStarted) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
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
            .padding(.horizontal, AppTheme.Spacing.xl)

            Text("Takes less than 30 seconds")
                .font(AppTheme.Typography.caption)
                .foregroundColor(.white.opacity(0.6))
                .padding(.bottom, AppTheme.Spacing.xl)
        }
    }
}

// MARK: - Processing Screen

struct ProcessingScreen: View {
    let progress: Double
    let answers: [String: String]

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.accent)
                    .rotationEffect(.degrees(progress * 360))
            }

            // Processing text
            VStack(spacing: AppTheme.Spacing.md) {
                Text("Analyzing your needs...")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(processingMessage)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
            }

            // Progress bar
            VStack(spacing: AppTheme.Spacing.sm) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                    .padding(.horizontal, AppTheme.Spacing.xl)
                    .animation(.linear, value: progress)

                Text("\(Int(progress * 100))%")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .animation(.linear, value: progress)
            }

            Spacer()
        }
    }

    private var processingMessage: String {
        if progress < 0.3 {
            return "Understanding your audience..."
        } else if progress < 0.6 {
            return "Finding the best features for you..."
        } else if progress < 0.9 {
            return "Creating your personalized plan..."
        } else {
            return "Almost ready!"
        }
    }
}

// MARK: - Models

struct OnboardingQuestion: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let icon: String
    let options: [OnboardingOption]
}

struct OnboardingOption: Identifiable {
    let id: String
    let title: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
}

// MARK: - Option Card

struct OnboardingOptionCard: View {
    let option: OnboardingOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.lg) {
                // Icon
                ZStack {
                    Circle()
                        .fill(option.color.opacity(isSelected ? 0.3 : 0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: option.icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? option.color : .white)
                }

                // Text
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(option.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppTheme.accent)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? AppTheme.accent : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Personalized Paywall

struct PersonalizedPaywallView: View {
    let answers: [String: String]
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var purchaseService = PurchaseService.shared
    @State private var selectedPlan: PaywallView.SubscriptionPlan = .weekly
    @State private var showingError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.primary, Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: AppTheme.Spacing.xxl) {
                    // Personalized headline
                    VStack(spacing: AppTheme.Spacing.xl) {
                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 110, height: 110)

                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(AppTheme.success)
                        }

                        VStack(spacing: AppTheme.Spacing.md) {
                            Text(personalizedHeadline)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)

                            Text(personalizedSubheadline)
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, AppTheme.Spacing.lg)
                        }
                    }
                    .padding(.top, AppTheme.Spacing.xl)

                    // Personalized benefits
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("Perfect For You")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)

                        VStack(spacing: AppTheme.Spacing.sm) {
                            ForEach(personalizedBenefits, id: \.title) { benefit in
                                PersonalizedBenefitRow(
                                    icon: benefit.icon,
                                    title: benefit.title,
                                    description: benefit.description
                                )
                            }
                        }
                    }
                    .glassCard(padding: AppTheme.Spacing.xl)

                    // Pricing - Simplified
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
                                "variant": "personalized",
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
                                "variant": "personalized",
                                "section": "primary"
                            ])
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.lg)

                    // Social Proof Section
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

                    // Testimonials Section
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("Success Stories")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        VStack(spacing: AppTheme.Spacing.sm) {
                            PersonalizedTestimonialCard(
                                avatar: "👨‍💼",
                                name: "Sarah M.",
                                rating: 5,
                                text: personalizedTestimonial1
                            )

                            PersonalizedTestimonialCard(
                                avatar: "👩‍💻",
                                name: "Mike P.",
                                rating: 5,
                                text: "The automation features save me hours every week. Best messaging app I've ever used!"
                            )

                            PersonalizedTestimonialCard(
                                avatar: "👨‍🎓",
                                name: "Alex K.",
                                rating: 5,
                                text: "Perfect for coordinating events. The template system makes everything so much easier."
                            )
                        }
                    }

                    // Secondary Pricing (for scrollers)
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("Choose Your Plan")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

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
                                    "variant": "personalized",
                                    "section": "secondary"
                                ])
                            }
                            .scaleEffect(0.98)

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
                                    "variant": "personalized",
                                    "section": "secondary"
                                ])
                            }
                            .scaleEffect(0.98)
                        }
                    }

                    // FAQ Section
                    PersonalizedFAQSection()

                    Spacer(minLength: AppTheme.Spacing.lg)
                }
                .padding(.horizontal, 20)
                .padding(.top, AppTheme.Spacing.xl)
                .padding(.bottom, AppTheme.Spacing.xl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: AppTheme.Spacing.sm) {
                Button(action: {
                    AnalyticsService.shared.track("personalized_paywall_cta_tapped", properties: answers)
                    Task {
                        await purchase()
                    }
                }) {
                    HStack {
                        if case .loading = purchaseService.purchaseState {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            VStack(spacing: AppTheme.Spacing.xs) {
                                Text(selectedPlan == .weekly ? "Start Your Free Trial" : "Get Yearly Plan")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)

                                Text(selectedPlan == .weekly ? "3 days free, then $9.99/week" : "$36.99/year • Save 69%")
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

                Text("Auto-renews. Cancel anytime.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.7))

                // Restore purchases button
                Button {
                    Task {
                        await restorePurchases()
                    }
                } label: {
                    Text("Restore Purchases")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .underline()
                }
                .padding(.top, 4)
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
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            AnalyticsService.shared.track("personalized_paywall_shown", properties: answers)
            // Track Facebook onboarding completion (only once)
            if !hasCompletedOnboarding {
                FacebookAnalyticsService.shared.trackOnboardingCompleted()
            }
            // Mark onboarding as completed now that they've seen the personalized paywall
            DispatchQueue.main.async {
                hasCompletedOnboarding = true
            }
        }
    }

    // MARK: - Purchase Logic

    private func purchase() async {
        if purchaseService.products.isEmpty {
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                purchaseService.isPurchased = true
            }
            #else
            showingError = true
            errorMessage = "Products not available. Please check your configuration."
            #endif
            return
        }

        let productToPurchase = selectedPlan == .weekly
            ? purchaseService.products.first { $0.id == "com.bulkmess.weekly" }
            : purchaseService.products.first { $0.id == "com.bulkmess.yearly" }

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

    // MARK: - Personalization Logic

    private var personalizedHeadline: String {
        let audience = answers["audience"] ?? "none"

        switch audience {
        case "business":
            return "Perfect for Your Business!"
        case "events":
            return "Event Coordination Made Easy!"
        case "community":
            return "Connect Your Community!"
        case "personal":
            return "Stay Connected with Loved Ones!"
        default:
            return "You're All Set!"
        }
    }

    private var personalizedSubheadline: String {
        let volume = answers["volume"] ?? "none"

        switch volume {
        case "few":
            return "Even small groups benefit from smart templates"
        case "dozens":
            return "Message dozens of contacts in seconds"
        case "hundreds":
            return "Reach hundreds instantly with bulk messaging"
        case "thousands":
            return "Scale your messaging to thousands effortlessly"
        default:
            return "Start messaging smarter today"
        }
    }

    private var personalizedBenefits: [(icon: String, title: String, description: String)] {
        var benefits: [(String, String, String)] = []

        let goal = answers["goal"] ?? "none"
        let challenge = answers["challenge"] ?? "none"
        let volume = answers["volume"] ?? "none"

        // Based on goal
        switch goal {
        case "marketing":
            benefits.append(("megaphone.fill", "Marketing Power", "Promotional campaigns that convert"))
        case "events":
            benefits.append(("calendar.badge.checkmark", "Event Success", "Keep attendees informed and engaged"))
        case "team":
            benefits.append(("person.3.sequence.fill", "Team Efficiency", "Streamline team communication"))
        case "updates":
            benefits.append(("bell.badge.fill", "Community Reach", "Keep everyone in the loop"))
        default:
            break
        }

        // Based on challenge
        switch challenge {
        case "time":
            benefits.append(("clock.arrow.2.circlepath", "Save Hours", "Automate repetitive messaging tasks"))
        case "personalize":
            benefits.append(("person.crop.circle.badge.checkmark", "Smart Personalization", "Templates with custom fields"))
        case "templates":
            benefits.append(("doc.text.fill", "Reusable Templates", "Create once, use forever"))
        case "tracking":
            benefits.append(("chart.line.uptrend.xyaxis", "Track Performance", "See delivery rates and analytics"))
        default:
            break
        }

        // Always add unlimited contacts
        benefits.append(("person.2.fill", "Unlimited Contacts", "No limits on your contact list"))

        // Add bulk sending based on volume
        if volume == "hundreds" || volume == "thousands" {
            benefits.append(("paperplane.fill", "Bulk Sending", "Send to \(volume == "hundreds" ? "hundreds" : "thousands") at once"))
        } else {
            benefits.append(("paperplane.fill", "Bulk Sending", "Message groups instantly"))
        }

        return Array(benefits.prefix(4)) // Show max 4 benefits
    }

    private var personalizedTestimonial1: String {
        let goal = answers["goal"] ?? "none"

        switch goal {
        case "marketing":
            return "BulkMess has revolutionized my business communications. I can now reach hundreds of clients instantly!"
        case "events":
            return "Perfect for event coordination! I can update all attendees in seconds. Game changer for my business."
        case "team":
            return "Managing team communications has never been easier. BulkMess keeps everyone in the loop effortlessly."
        case "updates":
            return "Keeping my community informed is now a breeze. BulkMess makes it so simple to reach everyone at once."
        default:
            return "BulkMess has revolutionized my business communications. I can now reach hundreds of clients instantly!"
        }
    }
}

struct PersonalizedBenefitRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accent)
                .font(.system(size: 24))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(AppTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct PersonalizedTestimonialCard: View {
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

struct PersonalizedFAQSection: View {
    @State private var expandedFAQ: Int? = nil

    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Frequently Asked Questions")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: AppTheme.Spacing.sm) {
                PersonalizedFAQItem(
                    question: "How does the free trial work?",
                    answer: "You get 3 days completely free with the weekly plan. Cancel anytime during the trial without being charged.",
                    isExpanded: expandedFAQ == 0
                ) {
                    expandedFAQ = expandedFAQ == 0 ? nil : 0
                }

                PersonalizedFAQItem(
                    question: "Can I cancel anytime?",
                    answer: "Yes, you can cancel your subscription at any time from your device settings. No questions asked.",
                    isExpanded: expandedFAQ == 1
                ) {
                    expandedFAQ = expandedFAQ == 1 ? nil : 1
                }

                PersonalizedFAQItem(
                    question: "Is my data secure?",
                    answer: "Absolutely. We use industry-standard encryption and never share your contact information with third parties.",
                    isExpanded: expandedFAQ == 2
                ) {
                    expandedFAQ = expandedFAQ == 2 ? nil : 2
                }

                PersonalizedFAQItem(
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

struct PersonalizedFAQItem: View {
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

#Preview {
    OnboardingView()
}
