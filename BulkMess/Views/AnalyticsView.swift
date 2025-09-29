import SwiftUI

struct AnalyticsView: View {
    @EnvironmentObject var campaignManager: CampaignManager

    var overallAnalytics: OverallAnalytics {
        campaignManager.getOverallAnalytics()
    }

    var body: some View {
        NavigationStack {
            Group {
                if campaignManager.campaigns.isEmpty {
                    EmptyStateCard(
                        icon: "chart.bar.fill",
                        title: "No Analytics Yet",
                        message: "Send your first campaigns to see detailed performance metrics and insights",
                        accentColor: AppTheme.accent
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.xl) {
                            // Modern Overall Statistics Cards
                            ModernOverallStatsSection(analytics: overallAnalytics)

                            // Recent Campaign Performance
                            if !campaignManager.campaigns.isEmpty {
                                ModernRecentCampaignsSection()
                            }

                            // Enhanced Insights Section
                            ModernInsightsSection(analytics: overallAnalytics)
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                    .background(AppTheme.background)
                }
            }
            .navigationTitle("Analytics")
        }
        .environmentObject(campaignManager)
    }
}

struct ModernOverallStatsSection: View {
    let analytics: OverallAnalytics

    var body: some View {
        SectionCard(title: "Overview", subtitle: "Campaign performance at a glance") {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.lg) {
                StatisticCard(
                    title: "Total Campaigns",
                    value: "\(analytics.totalCampaigns)",
                    subtitle: "\(analytics.completedCampaigns) completed",
                    icon: "megaphone.fill",
                    accentColor: AppTheme.accent,
                    trend: analytics.totalCampaigns > 0 ? .up("Active") : .neutral("None")
                )

                StatisticCard(
                    title: "Messages Sent",
                    value: "\(analytics.totalMessagesSent)",
                    subtitle: "to \(analytics.totalRecipients) recipients",
                    icon: "paperplane.fill",
                    accentColor: AppTheme.success,
                    trend: analytics.totalMessagesSent > 100 ? .up("High volume") : analytics.totalMessagesSent > 0 ? .neutral("Active") : .neutral("None")
                )

                StatisticCard(
                    title: "Success Rate",
                    value: String(format: "%.1f%%", analytics.averageSuccessRate),
                    subtitle: "average across campaigns",
                    icon: "chart.line.uptrend.xyaxis",
                    accentColor: analytics.averageSuccessRate >= 90 ? AppTheme.success : analytics.averageSuccessRate >= 70 ? AppTheme.warning : AppTheme.error,
                    trend: analytics.averageSuccessRate >= 90 ? .up("Excellent") : analytics.averageSuccessRate >= 70 ? .neutral("Good") : .down("Needs work")
                )

                StatisticCard(
                    title: "Active Campaigns",
                    value: "\(analytics.totalCampaigns - analytics.completedCampaigns)",
                    subtitle: "currently running",
                    icon: "clock.fill",
                    accentColor: AppTheme.warning,
                    trend: analytics.totalCampaigns - analytics.completedCampaigns > 0 ? .up("Running") : .neutral("None")
                )
            }
        }
    }
}

// Keep for backward compatibility
struct OverallStatsSection: View {
    let analytics: OverallAnalytics

    var body: some View {
        ModernOverallStatsSection(analytics: analytics)
    }
}

struct ModernRecentCampaignsSection: View {
    @EnvironmentObject var campaignManager: CampaignManager

    var body: some View {
        SectionCard(title: "Recent Campaigns", subtitle: "Latest campaign performance") {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                ForEach(campaignManager.getRecentCampaigns(), id: \.objectID) { campaign in
                    ModernCampaignAnalyticsCard(campaign: campaign)
                }
            }
        }
    }
}

// Keep for backward compatibility
struct RecentCampaignsSection: View {
    @EnvironmentObject var campaignManager: CampaignManager

    var body: some View {
        ModernRecentCampaignsSection()
    }
}

struct ModernInsightsSection: View {
    let analytics: OverallAnalytics

    var body: some View {
        SectionCard(title: "Insights", subtitle: "AI-powered recommendations") {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                FeatureCard(
                    icon: performanceIcon,
                    title: "Performance Trend",
                    description: performanceMessage,
                    accentColor: performanceColor
                )

                FeatureCard(
                    icon: "calendar.badge.clock",
                    title: "Campaign Activity",
                    description: activityMessage,
                    accentColor: AppTheme.accent
                )

                if analytics.averageSuccessRate < 80 {
                    FeatureCard(
                        icon: "lightbulb.fill",
                        title: "Success Rate Tips",
                        description: "Consider reviewing message templates and contact list quality to improve success rates",
                        accentColor: AppTheme.warning
                    )
                }
            }
        }
    }

    private var performanceMessage: String {
        let rate = analytics.averageSuccessRate
        if rate >= 95 {
            return "Excellent! Your campaigns are performing very well with \(String(format: "%.1f", rate))% success rate"
        } else if rate >= 80 {
            return "Good performance with \(String(format: "%.1f", rate))% success rate. Room for improvement"
        } else if rate >= 60 {
            return "Moderate performance at \(String(format: "%.1f", rate))%. Consider optimizing your approach"
        } else {
            return "Performance needs attention. Success rate is \(String(format: "%.1f", rate))%"
        }
    }

    private var performanceIcon: String {
        let rate = analytics.averageSuccessRate
        if rate >= 95 {
            return "star.fill"
        } else if rate >= 80 {
            return "arrow.up.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }

    private var performanceColor: Color {
        let rate = analytics.averageSuccessRate
        if rate >= 95 {
            return AppTheme.success
        } else if rate >= 80 {
            return AppTheme.accent
        } else {
            return AppTheme.warning
        }
    }

    private var activityMessage: String {
        let completed = analytics.completedCampaigns
        let total = analytics.totalCampaigns
        let active = total - completed

        if active > 0 {
            return "You have \(active) active campaign\(active == 1 ? "" : "s") and \(completed) completed"
        } else if completed > 0 {
            return "All \(completed) campaigns completed. Time to create more!"
        } else {
            return "No campaigns yet. Create your first campaign to get started"
        }
    }
}

// Keep for backward compatibility
struct InsightsSection: View {
    let analytics: OverallAnalytics

    var body: some View {
        ModernInsightsSection(analytics: analytics)
    }
}

struct InsightCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 1)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(color)
                    }

                Spacer()

                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ModernCampaignAnalyticsCard: View {
    @EnvironmentObject var campaignManager: CampaignManager
    let campaign: Campaign

    var analytics: CampaignAnalytics {
        campaignManager.getCampaignAnalytics(campaign)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.lg) {
                IconBadge(campaignIcon, color: campaignColor, size: 44)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(campaign.name ?? "Untitled Campaign")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                        if let dateCreated = campaign.dateCreated {
                            Text(dateCreated, style: .relative)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }

                Spacer()

                ModernCampaignStatusBadge(status: analytics.status)
            }

            HStack(spacing: AppTheme.Spacing.lg) {
                ModernAnalyticsMetric(
                    label: "Sent",
                    value: "\(analytics.sentCount)",
                    color: AppTheme.success
                )

                ModernAnalyticsMetric(
                    label: "Failed",
                    value: "\(analytics.failedCount)",
                    color: AppTheme.error
                )

                ModernAnalyticsMetric(
                    label: "Success Rate",
                    value: String(format: "%.1f%%", analytics.successRate),
                    color: AppTheme.accent
                )

                Spacer()
            }

            if analytics.totalRecipients > 0 {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    HStack {
                        Text("Progress")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.secondaryText)
                        Spacer()
                        Text("\(analytics.sentCount)/\(analytics.totalRecipients)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(.primary)
                    }

                    ProgressView(value: Double(analytics.sentCount), total: Double(analytics.totalRecipients))
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accent))
                        .scaleEffect(y: 1.5)
                }
                .padding(AppTheme.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                        .fill(AppTheme.accent.opacity(0.05))
                )
            }
        }
        .cardContainer()
    }

    private var campaignIcon: String {
        switch analytics.status.lowercased() {
        case "sending":
            return "paperplane.fill"
        case "completed":
            return "checkmark.circle.fill"
        case "failed":
            return "xmark.circle.fill"
        case "draft":
            return "doc.fill"
        default:
            return "megaphone.fill"
        }
    }

    private var campaignColor: Color {
        switch analytics.status.lowercased() {
        case "sending":
            return AppTheme.accent
        case "completed":
            return AppTheme.success
        case "failed":
            return AppTheme.error
        case "draft":
            return AppTheme.secondaryText
        default:
            return AppTheme.warning
        }
    }
}

struct ModernAnalyticsMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xs) {
            Text(value)
                .font(AppTheme.Typography.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.secondaryText)
        }
    }
}

// Keep for backward compatibility
struct CampaignAnalyticsRow: View {
    @EnvironmentObject var campaignManager: CampaignManager
    let campaign: Campaign

    var body: some View {
        ModernCampaignAnalyticsCard(campaign: campaign)
    }
}

struct AnalyticsMetric: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AnalyticsEmptyStateView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("No Analytics Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Send your first campaigns to see detailed performance metrics and insights")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                Text("Analytics will show:")
                    .font(.headline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                    AnalyticsFeatureRow(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Success Rates",
                        description: "Track message delivery performance"
                    )
                    AnalyticsFeatureRow(
                        icon: "speedometer",
                        title: "Campaign Metrics",
                        description: "Monitor sent vs failed messages"
                    )
                    AnalyticsFeatureRow(
                        icon: "lightbulb.fill",
                        title: "Smart Insights",
                        description: "Get tips to improve performance"
                    )
                    AnalyticsFeatureRow(
                        icon: "calendar.badge.clock",
                        title: "Activity Timeline",
                        description: "View campaign history and trends"
                    )
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(AppTheme.background)
    }
}

struct AnalyticsFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.template(ctx, name: "Notify", content: "Hello {{firstName}}")
        let contacts = (1...4).map { i in
            PreviewSeed.contact(ctx, firstName: "T\(i)", lastName: "User", phone: "+1555200\(i)")
        }
        _ = PreviewSeed.group(ctx, name: "Team", colorHex: "#5856D6", contacts: contacts)
        try? ctx.save()
        // After managers init, campaign creation
    }
    if let t = env.templateManager.templates.first, let g = env.contactManager.contactGroups.first {
        let camp1 = env.campaignManager.createCampaign(name: "Alpha", template: t, targetGroups: [g])
        camp1.status = "completed"; camp1.sentCount = 3; camp1.failedCount = 1
        let camp2 = env.campaignManager.createCampaign(name: "Beta", template: t, targetGroups: [g])
        camp2.status = "sending"; camp2.sentCount = 1; camp2.failedCount = 0
        try? env.ctx.save()
    }
    return AnalyticsView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.campaignManager)
}
