import SwiftUI

struct ContactGroupsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    @State private var showingAddGroup = false
    @State private var selectedGroup: ContactGroup?

    var body: some View {
        NavigationStack {
            Group {
                if contactManager.contactGroups.isEmpty {
                    ContactGroupsEmptyStateView(showingAddGroup: $showingAddGroup)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(contactManager.contactGroups, id: \.objectID) { group in
                                ContactGroupRowView(group: group) {
                                    selectedGroup = group
                                }
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.lg)
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                    .background(AppTheme.background)
                    .refreshable {
                        contactManager.reloadContactGroups()
                    }
                }
            }
            .navigationTitle("Contact Groups")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGroup = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddContactGroupView()
            }
            .sheet(item: $selectedGroup) { group in
                ContactGroupDetailView(group: group)
            }
            .onAppear {
                print("ContactGroupsView appeared. Groups count: \(contactManager.contactGroups.count)")
                // Force reload groups
                contactManager.reloadContactGroups()
            }
            .refreshable {
                contactManager.reloadContactGroups()
            }
        }
    }

    private func deleteGroups(offsets: IndexSet) {
        for index in offsets {
            let group = contactManager.contactGroups[index]
            contactManager.deleteContactGroup(group)
        }
    }
}

struct ContactGroupRowView: View {
    let group: ContactGroup
    let onTap: () -> Void
    @State private var isPressed = false

    private var groupColor: Color {
        if let colorHex = group.colorHex {
            return Color(hex: colorHex)
        }
        return AppTheme.accent
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Modern Group Icon with gradient
            IconBadge("folder.fill", color: groupColor, size: 56)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(group.name ?? "Unnamed Group")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: AppTheme.Spacing.lg) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(AppTheme.accent)
                        Text("\(group.contacts?.count ?? 0) contacts")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }

                    if let dateCreated = group.dateCreated {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(AppTheme.accent)
                            Text("Created \(dateCreated, style: .relative)")
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                }
            }

            Spacer()

            // Modern chevron with animation
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.accent)
                .scaleEffect(isPressed ? 1.2 : 1.0)
                .animation(AppAnimations.bouncy, value: isPressed)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(AppTheme.cardBackground)
                .shadow(
                    color: AppTheme.Shadow.medium,
                    radius: isPressed ? 12 : 6,
                    x: 0,
                    y: isPressed ? 4 : 2
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            // Provide immediate feedback
            withAnimation(AppAnimations.subtle) {
                isPressed = true
            }

            // Call the action
            onTap()

            // Reset state quickly to avoid blocking subsequent taps
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(AppAnimations.subtle) {
                    isPressed = false
                }
            }
        }
        .animation(AppAnimations.spring, value: isPressed)
    }
}

struct ContactGroupsEmptyStateView: View {
    @Binding var showingAddGroup: Bool
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            VStack(spacing: AppTheme.Spacing.xl) {
                // Animated hero icon
                IconBadge("folder.badge.gearshape", color: AppTheme.accent, size: 100)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                    .onAppear {
                        animateIcon = true
                    }

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("No Contact Groups")
                        .font(AppTheme.Typography.title)
                        .foregroundColor(.primary)

                    Text("Create groups to organize your contacts by category, project, or any way that makes sense")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }

            VStack(spacing: AppTheme.Spacing.xl) {
                Button {
                    showingAddGroup = true
                } label: {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        Image(systemName: "folder.fill.badge.plus")
                            .font(.title3)
                        Text("Create First Group")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                VStack(spacing: AppTheme.Spacing.lg) {
                    Text("Group Benefits")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)

                    VStack(spacing: AppTheme.Spacing.md) {
                        BenefitRow(
                            icon: "target",
                            text: "Send targeted campaigns",
                            color: AppTheme.accent
                        )
                        BenefitRow(
                            icon: "rectangle.stack.fill",
                            text: "Better contact organization",
                            color: AppTheme.success
                        )
                        BenefitRow(
                            icon: "speedometer",
                            text: "Faster bulk messaging",
                            color: AppTheme.warning
                        )
                    }
                }
                .glassCard()
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(AppTheme.Typography.callout)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

#Preview("Contact Groups") {
    let env = PreviewEnvironment.make { ctx in
        let c = PreviewSeed.contact(ctx, firstName: "Mia", lastName: "Chen", phone: "+15558888")
        _ = PreviewSeed.group(ctx, name: "Friends", colorHex: "#FF375F", contacts: [c])
    }
    return ContactGroupsView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}

#Preview("Group Row") {
    let env = PreviewEnvironment.make { ctx in
        let c = PreviewSeed.contact(ctx, firstName: "Mia", lastName: "Chen", phone: "+15558888")
        _ = PreviewSeed.group(ctx, name: "Friends", colorHex: "#FF375F", contacts: [c])
    }
    return VStack {
        if let group = env.contactManager.contactGroups.first {
            ContactGroupRowView(group: group) {
                print("Group tapped!")
            }
        }
    }
    .padding()
    .environment(\.managedObjectContext, env.ctx)
    .environmentObject(env.contactManager)
}
