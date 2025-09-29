import SwiftUI

struct TemplatesView: View {
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var contactManager: ContactManager
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var searchText = ""
    @State private var showingAddTemplate = false
    @State private var selectedTemplate: MessageTemplate?

    var filteredTemplates: [MessageTemplate] {
        templateManager.searchTemplates(searchText)
    }

    var favoriteTemplates: [MessageTemplate] {
        templateManager.getFavoriteTemplates()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if templateManager.templates.isEmpty {
                    EmptyStateCard(
                        icon: "doc.text.fill",
                        title: "No Templates Yet",
                        message: "Create reusable message templates to save time when sending bulk messages",
                        buttonTitle: "Create Template",
                        buttonAction: { showingAddTemplate = true },
                        accentColor: AppTheme.accent
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.lg) {
                            if !favoriteTemplates.isEmpty {
                                SectionCard(title: "Favorites", subtitle: "Your most used templates") {
                                    LazyVStack(spacing: AppTheme.Spacing.md) {
                                        ForEach(favoriteTemplates, id: \.objectID) { template in
                                            ModernTemplateCard(template: template) {
                                                selectedTemplate = template
                                            }
                                        }
                                    }
                                }
                            }

                            SectionCard(title: "All Templates", subtitle: "\(filteredTemplates.count) templates available") {
                                LazyVStack(spacing: AppTheme.Spacing.md) {
                                    ForEach(filteredTemplates, id: \.objectID) { template in
                                        ModernTemplateCard(template: template) {
                                            selectedTemplate = template
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                    .background(AppTheme.background)
                    .searchable(text: $searchText, prompt: "Search...")
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .background(AppTheme.background)
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                AddTemplateView()
            }
            .sheet(item: $selectedTemplate) { template in
                TemplateDetailView(template: template)
            }

            if hSizeClass == .regular, !templateManager.templates.isEmpty {
                TemplateDetailPlaceholderView()
            }
        }
    }

    private func deleteTemplates(offsets: IndexSet) {
        for index in offsets {
            templateManager.deleteTemplate(filteredTemplates[index])
        }
    }
}

struct ModernTemplateCard: View {
    @EnvironmentObject var templateManager: MessageTemplateManager
    let template: MessageTemplate
    let onTap: (() -> Void)?
    @State private var isPressed = false

    init(template: MessageTemplate, onTap: (() -> Void)? = nil) {
        self.template = template
        self.onTap = onTap
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
            HStack(spacing: AppTheme.Spacing.lg) {
                IconBadge("doc.text.fill", color: AppTheme.accent, size: 50)

                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(template.name ?? "Untitled Template")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    HStack(spacing: AppTheme.Spacing.md) {
                        if let dateModified = template.dateModified {
                            HStack(spacing: AppTheme.Spacing.xs) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.accent)
                                Text("Modified \(dateModified, style: .relative)")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }
                        }
                    }
                }

                Spacer()

                VStack(spacing: AppTheme.Spacing.sm) {
                    Button {
                        templateManager.toggleTemplateFavorite(template)
                    } label: {
                        Image(systemName: template.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(template.isFavorite ? AppTheme.error : AppTheme.secondaryText)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(AppAnimations.bouncy, value: isPressed)

                    if template.usageCount > 0 {
                        StatusPill(
                            text: "\(template.usageCount) uses",
                            background: AppTheme.success,
                            foreground: AppTheme.success
                        )
                    }
                }
            }

            if let content = template.content, !content.isEmpty {
                Text(content)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(3)
                    .padding(AppTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                            .fill(AppTheme.accent.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.Radius.small)
                                    .stroke(AppTheme.accent.opacity(0.1), lineWidth: 1)
                            )
                    )
            }

            HStack {
                Image(systemName: "hand.tap")
                    .font(.caption)
                    .foregroundColor(AppTheme.accent)
                Text("Tap to edit")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.accent)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(AppAnimations.bouncy, value: isPressed)
            }
        }
        .cardContainer()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppAnimations.spring, value: isPressed)
        .onTapGesture {
            withAnimation(AppAnimations.spring) {
                isPressed = true
            }

            // Call the action if provided
            onTap?()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimations.spring) {
                    isPressed = false
                }
            }
        }
    }
}

// Keep the old view for backward compatibility
struct TemplateRowView: View {
    @EnvironmentObject var templateManager: MessageTemplateManager
    let template: MessageTemplate

    var body: some View {
        ModernTemplateCard(template: template)
    }
}

struct TemplatesEmptyStateView: View {
    @Binding var showingAddTemplate: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("No Templates Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Create reusable message templates to save time when sending bulk messages")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: AppTheme.Spacing.lg) {
                Button {
                    showingAddTemplate = true
                } label: {
                    Label("Create Template", systemImage: "doc.text.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("Templates can include:")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(.blue)
                                .frame(width: 16)
                            Text("Personalized names")
                        }
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.green)
                                .frame(width: 16)
                            Text("Dynamic dates")
                        }
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(.orange)
                                .frame(width: 16)
                            Text("Custom variables")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct TemplateDetailPlaceholderView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Select a Template")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Choose a template to view and edit its content")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(AppTheme.background)
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.template(ctx, name: "Welcome", content: "Hello {{firstName}}")
        _ = PreviewSeed.contact(ctx, firstName: "Sam", lastName: "Lee", phone: "+155503")
    }
    return TemplatesView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.templateManager)
        .environmentObject(env.contactManager)
}
