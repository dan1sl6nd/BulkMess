import SwiftUI

enum AppTheme {
    // Modern Color Palette
    static let primary = Color(red: 0.1, green: 0.1, blue: 0.2)
    static let accent = Color(red: 0.2, green: 0.6, blue: 1.0)
    static let accentSecondary = Color(red: 0.4, green: 0.8, blue: 0.6)
    static let background = Color(.systemGroupedBackground)
    static let cardBackground = Color(.systemBackground)
    static let secondaryText = Color.secondary
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let error = Color(red: 1.0, green: 0.3, blue: 0.3)

    // Gradient Colors
    static let primaryGradient = LinearGradient(
        colors: [accent, accentSecondary],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let cardGradient = LinearGradient(
        colors: [cardBackground, cardBackground.opacity(0.8)],
        startPoint: .top,
        endPoint: .bottom
    )

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 8
        static let card: CGFloat = 16
        static let large: CGFloat = 20
        static let pill: CGFloat = 50
    }

    enum Shadow {
        static let light = Color.black.opacity(0.03)
        static let medium = Color.black.opacity(0.08)
        static let strong = Color.black.opacity(0.15)
    }

    enum Typography {
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let title2 = Font.title2.weight(.semibold)
        static let headline = Font.headline.weight(.medium)
        static let body = Font.body
        static let callout = Font.callout.weight(.medium)
        static let caption = Font.caption.weight(.medium)
    }
}

// MARK: - Enhanced Card Container
struct CardContainer: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.lg
    var radius: CGFloat = AppTheme.Radius.card
    var shadowOpacity: Double = 0.08

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.Shadow.medium, radius: 8, x: 0, y: 2)
            )
    }
}

struct GlassCard: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.lg
    var radius: CGFloat = AppTheme.Radius.card

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: AppTheme.Shadow.light, radius: 4, x: 0, y: 1)
            )
    }
}

struct HeroCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(AppTheme.primaryGradient)
                    .shadow(color: AppTheme.accent.opacity(0.3), radius: 12, x: 0, y: 4)
            )
    }
}

extension View {
    func cardContainer(padding: CGFloat = AppTheme.Spacing.lg, radius: CGFloat = AppTheme.Radius.card) -> some View {
        modifier(CardContainer(padding: padding, radius: radius))
    }

    func glassCard(padding: CGFloat = AppTheme.Spacing.lg) -> some View {
        modifier(GlassCard(padding: padding))
    }

    func heroCard() -> some View {
        modifier(HeroCard())
    }
}

// MARK: - Enhanced Status Components
struct StatusPill: View {
    let text: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(text)
            .font(AppTheme.Typography.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.xs)
            .background(
                Capsule()
                    .fill(background.opacity(0.15))
            )
            .foregroundColor(foreground)
            .overlay(
                Capsule()
                    .stroke(background.opacity(0.3), lineWidth: 1)
            )
    }
}

struct IconBadge: View {
    let icon: String
    let color: Color
    let size: CGFloat

    init(_ icon: String, color: Color = AppTheme.accent, size: CGFloat = 44) {
        self.icon = icon
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [color.opacity(0.8), color],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundColor(.white)
            )
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Modern Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.callout)
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(AppTheme.primaryGradient)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .shadow(
                color: AppTheme.accent.opacity(configuration.isPressed ? 0.5 : 0.3),
                radius: configuration.isPressed ? 8 : 12,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.callout)
            .foregroundColor(AppTheme.accent)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .padding(.vertical, AppTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(AppTheme.accent.opacity(0.3), lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .fill(AppTheme.accent.opacity(configuration.isPressed ? 0.1 : 0.05))
                    )
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            )
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Advanced Card Components
struct DashboardCard: ViewModifier {
    var padding: CGFloat = AppTheme.Spacing.xl

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.Shadow.medium, radius: 12, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.large)
                            .stroke(AppTheme.accent.opacity(0.1), lineWidth: 1)
                    )
            )
    }
}

struct MetricCard: ViewModifier {
    let accentColor: Color

    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(
                        LinearGradient(
                            colors: [
                                accentColor.opacity(0.05),
                                accentColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct SettingsCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(AppTheme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .fill(AppTheme.cardBackground)
                    .shadow(color: AppTheme.Shadow.light, radius: 6, x: 0, y: 2)
            )
    }
}

struct InteractiveCard: ViewModifier {
    @State private var isPressed = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(color: AppTheme.Shadow.medium, radius: isPressed ? 6 : 10, x: 0, y: isPressed ? 2 : 4)
            .animation(AppAnimations.spring, value: isPressed)
            // Removed onTapGesture to avoid conflicts with Button actions
    }
}

extension View {
    func dashboardCard(padding: CGFloat = AppTheme.Spacing.xl) -> some View {
        modifier(DashboardCard(padding: padding))
    }

    func metricCard(accentColor: Color = AppTheme.accent) -> some View {
        modifier(MetricCard(accentColor: accentColor))
    }

    func settingsCard() -> some View {
        modifier(SettingsCard())
    }

    func interactiveCard() -> some View {
        modifier(InteractiveCard())
    }
}

// MARK: - Advanced Components
struct StatisticCard: View {
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let accentColor: Color
    let trend: StatTrend?

    enum StatTrend {
        case up(String)
        case down(String)
        case neutral(String)

        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return AppTheme.success
            case .down: return AppTheme.error
            case .neutral: return AppTheme.secondaryText
            }
        }

        var text: String {
            switch self {
            case .up(let text), .down(let text), .neutral(let text): return text
            }
        }
    }

    init(title: String, value: String, subtitle: String? = nil, icon: String, accentColor: Color = AppTheme.accent, trend: StatTrend? = nil) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.trend = trend
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                IconBadge(icon, color: accentColor, size: 44)

                Spacer()

                if let trend = trend {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: trend.icon)
                            .font(.caption)
                        Text(trend.text)
                            .font(AppTheme.Typography.caption)
                    }
                    .foregroundColor(trend.color)
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(trend.color.opacity(0.1))
                    )
                }
            }

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(value)
                    .font(AppTheme.Typography.largeTitle)
                    .foregroundColor(.primary)

                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.secondaryText)
                        .lineLimit(2)
                }
            }
        }
        .metricCard(accentColor: accentColor)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
    let action: (() -> Void)?

    init(icon: String, title: String, description: String, accentColor: Color = AppTheme.accent, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.description = description
        self.accentColor = accentColor
        self.action = action
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            IconBadge(icon, color: accentColor, size: 50)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(nil)
            }

            Spacer()

            if action != nil {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(accentColor)
            }
        }
        .cardContainer()
        .if(action != nil) { view in
            view.onTapGesture {
                action?()
            }
        }
    }
}

struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(title)
                    .font(AppTheme.Typography.title2)
                    .foregroundColor(.primary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppTheme.Typography.callout)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }

            content
        }
        .dashboardCard()
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let accentColor: Color
    let animated: Bool

    @State private var iconScale: CGFloat = 1.0

    init(icon: String, title: String, message: String, buttonTitle: String? = nil, buttonAction: (() -> Void)? = nil, accentColor: Color = AppTheme.accent, animated: Bool = true) {
        self.icon = icon
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.accentColor = accentColor
        self.animated = animated
    }

    var body: some View {
        let baseSize: CGFloat = 100
        VStack(spacing: AppTheme.Spacing.xxl) {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Anchor the icon inside a fixed-size container; only the overlay scales
                Color.clear
                    .frame(width: baseSize, height: baseSize)
                    .overlay(
                        IconBadge(icon, color: accentColor, size: baseSize)
                            .scaleEffect(animated ? iconScale : 1.0)
                    )
                    .onAppear {
                        if animated {
                            withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                                iconScale = 1.1
                            }
                        }
                    }

                VStack(spacing: AppTheme.Spacing.md) {
                    Text(title)
                        .font(AppTheme.Typography.title)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    Text(message)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }

            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "plus")
                            .font(.title3)
                        Text(buttonTitle)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - Utility Extensions
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Animation Presets
enum AppAnimations {
    static let spring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let easeInOut = Animation.easeInOut(duration: 0.3)
    static let bouncy = Animation.interpolatingSpring(stiffness: 300, damping: 15)
    static let subtle = Animation.easeInOut(duration: 0.2)
}
