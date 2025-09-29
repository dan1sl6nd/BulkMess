import SwiftUI
import Contacts

struct ContactsView: View {
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var errorHandler: ErrorHandler
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var searchText = ""
    @State private var showingAddContact = false
    @State private var showingGroups = false
    @State private var isImporting = false
    @State private var selectedContact: Contact?

    var filteredContacts: [Contact] {
        contactManager.searchContacts(searchText)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if contactManager.permissionStatus != .authorized {
                    ContactsPermissionView()
                } else if filteredContacts.isEmpty && searchText.isEmpty {
                    ContactsEmptyStateView(showingAddContact: $showingAddContact)
                } else {
                    List {
                        ForEach(filteredContacts, id: \.objectID) { contact in
                            ContactRowView(contact: contact) {
                                selectedContact = contact
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .padding(.vertical, 4)
                            .cardContainer()
                        }
                        .onDelete(perform: deleteContacts)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.background)
                    .searchable(text: $searchText, prompt: "Search...")
                    .refreshable { await refreshContacts() }
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingGroups = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.fill")
                            Text("\(contactManager.contactGroups.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingGroups = true
                        } label: {
                            Label("Manage Groups", systemImage: "folder.fill")
                        }

                        Divider()

                        if contactManager.permissionStatus == .authorized {
                            Button {
                                Task { await refreshContacts() }
                            } label: {
                                Label("Sync Contacts", systemImage: isImporting ? "arrow.clockwise" : "arrow.2.circlepath")
                            }
                            .disabled(isImporting)
                        }

                        Button {
                            showingAddContact = true
                        } label: {
                            Label("Add Contact", systemImage: "person.crop.circle.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddContact) {
                AddContactView()
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact)
            }
            .sheet(isPresented: $showingGroups) {
                ContactGroupsView()
            }

            if hSizeClass == .regular,
               !filteredContacts.isEmpty || contactManager.permissionStatus == .authorized {
                ContactDetailPlaceholderView()
            }
        }
    }

    private func deleteContacts(offsets: IndexSet) {
        for index in offsets {
            contactManager.deleteContact(filteredContacts[index])
        }
    }

    private func refreshContacts() async {
        isImporting = true
        defer {
            Task { @MainActor in
                isImporting = false
            }
        }

        do {
            try await contactManager.importDeviceContacts()
        } catch {
            if let contactError = error as? ContactError {
                errorHandler.handle(contactError.asAppError)
            } else {
                errorHandler.handle(AppError.unknown(error.localizedDescription))
            }
        }
    }
}

struct ContactRowView: View {
    let contact: Contact
    let onTap: (() -> Void)?
    @State private var isPressed = false

    init(contact: Contact, onTap: (() -> Void)? = nil) {
        self.contact = contact
        self.onTap = onTap
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Modern Avatar with gradient
            IconBadge("person.fill", color: avatarColor, size: 50)
                .overlay(
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Text(contactName)
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    if contact.isFromDeviceContacts {
                        StatusPill(
                            text: "Device",
                            background: AppTheme.success,
                            foreground: AppTheme.success
                        )
                    }
                }

                Text(contact.phoneNumber ?? "No phone")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)

                if let email = contact.email, !email.isEmpty {
                    Text(email)
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.accent)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: AppTheme.Spacing.xs) {
                if let groups = contact.groups, groups.count > 0 {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(AppTheme.accent)
                            .font(.caption)
                        Text("\(groups.count)")
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, AppTheme.Spacing.xs)
                    .background(
                        Capsule()
                            .fill(AppTheme.accent.opacity(0.1))
                    )
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(AppAnimations.bouncy, value: isPressed)
            }
        }
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppAnimations.spring, value: isPressed)
        .onTapGesture {
            // Quick feedback without blocking
            withAnimation(AppAnimations.subtle) {
                isPressed = true
            }

            // Call the action if provided
            onTap?()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                withAnimation(AppAnimations.subtle) {
                    isPressed = false
                }
            }
        }
    }

    private var contactName: String {
        let firstName = contact.firstName ?? ""
        let lastName = contact.lastName ?? ""

        if firstName.isEmpty && lastName.isEmpty {
            return "Unknown Contact"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }

    private var initials: String {
        let firstName = contact.firstName ?? ""
        let lastName = contact.lastName ?? ""

        if firstName.isEmpty && lastName.isEmpty {
            return "?"
        }

        let firstInitial = firstName.isEmpty ? "" : String(firstName.prefix(1))
        let lastInitial = lastName.isEmpty ? "" : String(lastName.prefix(1))

        return (firstInitial + lastInitial).uppercased()
    }

    private var avatarColor: Color {
        let colors: [Color] = [AppTheme.accent, AppTheme.success, AppTheme.warning, AppTheme.error, AppTheme.accentSecondary]
        let hash = contactName.hash
        return colors[abs(hash) % colors.count]
    }
}

struct ContactsPermissionView: View {
    @EnvironmentObject var contactManager: ContactManager

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Access to Contacts Required")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("To import and manage your contacts, please grant access to your device contacts.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button("Grant Access") {
                Task {
                    await contactManager.requestContactsPermission()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
    }
}

struct ContactsEmptyStateView: View {
    @Binding var showingAddContact: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "person.2.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("No Contacts Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Add your first contact to start sending messages")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: AppTheme.Spacing.md) {
                Button {
                    showingAddContact = true
                } label: {
                    Label("Add Contact", systemImage: "person.crop.circle.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Text("or pull down to sync your device contacts")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct ContactDetailPlaceholderView: View {
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Image(systemName: "person.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            VStack(spacing: AppTheme.Spacing.sm) {
                Text("Select a Contact")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Choose a contact to view their details")
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
        _ = PreviewSeed.contact(ctx, firstName: "Jane", lastName: "Doe", phone: "+155501")
        _ = PreviewSeed.contact(ctx, firstName: "Mark", lastName: "Twain", phone: "+155502")
    }
    return ContactsView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
