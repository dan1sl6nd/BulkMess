import SwiftUI
import Contacts

struct SettingsView: View {
    @EnvironmentObject var contactManager: ContactManager
    @State private var showingPermissionsAlert = false
    @State private var showingAbout = false

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xl) {
                    // App Overview Card
                    SectionCard(title: "BulkMess", subtitle: "Powerful bulk messaging made simple") {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            HStack(spacing: AppTheme.Spacing.lg) {
                                IconBadge("megaphone.fill", color: AppTheme.accent, size: 60)

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Version 1.0.0")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(.primary)

                                    Text("Send messages to hundreds of contacts")
                                        .font(AppTheme.Typography.callout)
                                        .foregroundColor(AppTheme.secondaryText)
                                }

                                Spacer()
                            }

                            Button {
                                showingAbout = true
                            } label: {
                                HStack {
                                    Text("About BulkMess")
                                        .fontWeight(.medium)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .medium))
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }

                    // Contacts Management Card
                    SectionCard(title: "Contacts", subtitle: "Manage your contact list and permissions") {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            // Permission Status
                            ModernContactsPermissionCard()

                            // Contact Count
                            HStack(spacing: AppTheme.Spacing.lg) {
                                IconBadge("person.2.fill", color: AppTheme.success, size: 44)

                                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                    Text("Total Contacts")
                                        .font(AppTheme.Typography.headline)
                                        .foregroundColor(.primary)

                                    Text("Contacts available in your library")
                                        .font(AppTheme.Typography.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }

                                Spacer()

                                Text("\(contactManager.contacts.count)")
                                    .font(AppTheme.Typography.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.accent)
                            }
                            .settingsCard()

                            // Sync Button
                            Button {
                                Task {
                                    if contactManager.permissionStatus == .authorized || contactManager.permissionStatus == .limited {
                                        try? await contactManager.importDeviceContacts()
                                    } else {
                                        showingPermissionsAlert = true
                                    }
                                }
                            } label: {
                                HStack(spacing: AppTheme.Spacing.sm) {
                                    Image(systemName: "arrow.2.circlepath")
                                    Text("Sync Device Contacts")
                                        .fontWeight(.medium)
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(contactManager.permissionStatus != .authorized && contactManager.permissionStatus != .limited)
                        }
                    }

                    // App Features Overview
                    SectionCard(title: "Features", subtitle: "What BulkMess can do for you") {
                        VStack(spacing: AppTheme.Spacing.md) {
                            FeatureCard(
                                icon: "doc.text.fill",
                                title: "Smart Templates",
                                description: "Create reusable message templates with personalization",
                                accentColor: AppTheme.accent
                            )

                            FeatureCard(
                                icon: "person.2.fill",
                                title: "Contact Groups",
                                description: "Organize contacts into manageable groups",
                                accentColor: AppTheme.success
                            )

                            FeatureCard(
                                icon: "megaphone.fill",
                                title: "Bulk Campaigns",
                                description: "Send messages to hundreds of contacts at once",
                                accentColor: AppTheme.warning
                            )

                            FeatureCard(
                                icon: "chart.bar.fill",
                                title: "Analytics",
                                description: "Track delivery rates and campaign performance",
                                accentColor: AppTheme.error
                            )
                        }
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.sm)
            }
            .background(AppTheme.background)
            .navigationTitle("Settings")
            .alert("Contacts Permission Required", isPresented: $showingPermissionsAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Open Settings") {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }
            } message: {
                Text("Please enable contacts access in Settings to import your device contacts.")
            }
            .sheet(isPresented: $showingAbout) {
                ModernAboutView()
            }
        }
    }
}

struct ModernContactsPermissionCard: View {
    @EnvironmentObject var contactManager: ContactManager

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            IconBadge(permissionIcon, color: permissionColor, size: 44)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text("Contacts Access")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)

                Text(permissionDescription)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(AppTheme.secondaryText)
            }

            Spacer()

            StatusPill(
                text: permissionStatusText,
                background: permissionColor,
                foreground: permissionColor
            )
        }
        .settingsCard()
    }

    private var permissionIcon: String {
        switch contactManager.permissionStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .limited:
            return "checkmark.circle"
        case .denied, .restricted:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "questionmark.circle"
        }
    }

    private var permissionColor: Color {
        switch contactManager.permissionStatus {
        case .authorized:
            return AppTheme.success
        case .limited:
            return AppTheme.warning
        case .denied, .restricted:
            return AppTheme.error
        case .notDetermined:
            return AppTheme.warning
        @unknown default:
            return AppTheme.secondaryText
        }
    }

    private var permissionStatusText: String {
        switch contactManager.permissionStatus {
        case .authorized:
            return "Granted"
        case .limited:
            return "Limited"
        case .denied, .restricted:
            return "Denied"
        case .notDetermined:
            return "Not Requested"
        @unknown default:
            return "Unknown"
        }
    }

    private var permissionDescription: String {
        switch contactManager.permissionStatus {
        case .authorized:
            return "Full access to your contacts"
        case .limited:
            return "Limited access to selected contacts"
        case .denied, .restricted:
            return "Access denied - enable in Settings"
        case .notDetermined:
            return "Permission not yet requested"
        @unknown default:
            return "Unknown permission status"
        }
    }
}

// Keep for backward compatibility
struct ContactsPermissionRow: View {
    @EnvironmentObject var contactManager: ContactManager

    var body: some View {
        ModernContactsPermissionCard()
    }
}


struct ModernAboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xxl) {
                    // Hero Section
                    VStack(spacing: AppTheme.Spacing.xl) {
                        IconBadge("megaphone.fill", color: AppTheme.accent, size: 100)

                        VStack(spacing: AppTheme.Spacing.md) {
                            Text("BulkMess")
                                .font(AppTheme.Typography.largeTitle)
                                .foregroundColor(.primary)

                            Text("Version 1.0.0")
                                .font(AppTheme.Typography.headline)
                                .foregroundColor(AppTheme.secondaryText)
                        }
                    }
                    .heroCard()

                    // Description Section
                    SectionCard(title: "About BulkMess", subtitle: "Powerful bulk messaging made simple") {
                        VStack(spacing: AppTheme.Spacing.lg) {
                            Text("Send personalized messages to hundreds of contacts with customizable templates and Shortcuts integration.")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(AppTheme.secondaryText)
                                .multilineTextAlignment(.center)

                            Text("Built for efficiency, designed for simplicity.")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(AppTheme.accent)
                                .fontWeight(.medium)
                                .multilineTextAlignment(.center)
                        }
                    }

                    // Features Section
                    SectionCard(title: "Key Features", subtitle: "Everything you need for bulk messaging") {
                        VStack(spacing: AppTheme.Spacing.md) {
                            ModernFeatureRow(
                                icon: "person.2.fill",
                                title: "Contact Management",
                                description: "Import and organize your contacts into groups",
                                color: AppTheme.success
                            )

                            ModernFeatureRow(
                                icon: "doc.text.fill",
                                title: "Smart Templates",
                                description: "Create reusable message templates with personalization",
                                color: AppTheme.accent
                            )

                            ModernFeatureRow(
                                icon: "paperplane.fill",
                                title: "Bulk Messaging",
                                description: "Send to hundreds of contacts at once",
                                color: AppTheme.warning
                            )

                            ModernFeatureRow(
                                icon: "chart.bar.fill",
                                title: "Analytics",
                                description: "Track delivery rates and performance",
                                color: AppTheme.error
                            )

                            ModernFeatureRow(
                                icon: "arrow.triangle.2.circlepath",
                                title: "Shortcuts Integration",
                                description: "Automate with Apple Shortcuts",
                                color: AppTheme.accentSecondary
                            )
                        }
                    }

                    // Footer
                    VStack(spacing: AppTheme.Spacing.md) {
                        Text("Made with ❤️ for effective communication")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)

                        Text("© 2024 BulkMess. All rights reserved.")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.secondaryText)
                    }
                    .glassCard()
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.sm)
            }
            .background(AppTheme.background)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModernFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            IconBadge(icon, color: color, size: 44)

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
        }
        .settingsCard()
    }
}

// Keep for backward compatibility
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ModernAboutView()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
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
        _ = PreviewSeed.contact(ctx, firstName: "Chris", lastName: "P.", phone: "+15550000")
    }
    return SettingsView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
