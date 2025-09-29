import SwiftUI

struct ContactGroupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    let group: ContactGroup
    @State private var isEditing = false
    @State private var showingAddContacts = false
    @State private var selectedContact: Contact?

    private var groupContacts: [Contact] {
        (group.contacts?.allObjects as? [Contact]) ?? []
    }

    private var groupColor: Color {
        if let colorHex = group.colorHex {
            return Color(hex: colorHex)
        }
        return .blue
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Modern Group Header
                GroupHeaderView(group: group, groupColor: groupColor)
                    .padding(AppTheme.Spacing.lg)

                if groupContacts.isEmpty {
                    GroupEmptyStateView(showingAddContacts: $showingAddContacts)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            // Section Header
                            HStack {
                                Text("\(groupContacts.count) Contacts")
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, AppTheme.Spacing.lg)
                            .padding(.top, AppTheme.Spacing.lg)

                            // Contact Cards
                            ForEach(groupContacts, id: \.objectID) { contact in
                                ContactRowView(contact: contact) {
                                    selectedContact = contact
                                }
                                .cardContainer()
                                .padding(.horizontal, AppTheme.Spacing.lg)
                            }
                        }
                    }
                    .background(AppTheme.background)
                }
            }
            .navigationTitle(group.name ?? "Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        showingAddContacts = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }

                    Menu {
                        Button {
                            isEditing = true
                        } label: {
                            Label("Edit Group", systemImage: "pencil")
                        }

                        Divider()

                        Button(role: .destructive) {
                            contactManager.deleteContactGroup(group)
                            dismiss()
                        } label: {
                            Label("Delete Group", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingAddContacts) {
                AddContactsToGroupView(group: group)
            }
            .sheet(isPresented: $isEditing) {
                EditContactGroupView(group: group, isEditing: $isEditing)
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact)
            }
        }
    }

    private func removeContactsFromGroup(offsets: IndexSet) {
        for index in offsets {
            let contact = groupContacts[index]
            contactManager.removeContactFromGroup(contact, group: group)
        }
    }
}

struct GroupHeaderView: View {
    let group: ContactGroup
    let groupColor: Color

    var body: some View {
        HStack(spacing: AppTheme.Spacing.xl) {
            // Modern icon with gradient
            IconBadge("folder.fill", color: groupColor, size: 80)

            VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                Text(group.name ?? "Unnamed Group")
                    .font(AppTheme.Typography.title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)

                HStack(spacing: AppTheme.Spacing.xl) {
                    HStack(spacing: AppTheme.Spacing.xs) {
                        Image(systemName: "person.2.fill")
                            .font(.callout)
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(group.contacts?.count ?? 0) contacts")
                            .font(AppTheme.Typography.callout)
                            .foregroundColor(.white.opacity(0.9))
                    }

                    if let dateCreated = group.dateCreated {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "calendar")
                                .font(.callout)
                                .foregroundColor(.white.opacity(0.9))
                            Text("Created \(dateCreated, style: .relative)")
                                .font(AppTheme.Typography.callout)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }

            Spacer()
        }
        .heroCard()
    }
}

struct GroupEmptyStateView: View {
    @Binding var showingAddContacts: Bool
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xxl) {
            VStack(spacing: AppTheme.Spacing.xl) {
                IconBadge("person.2.badge.plus", color: AppTheme.accent, size: 80)
                    .scaleEffect(animateIcon ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateIcon
                    )
                    .onAppear {
                        animateIcon = true
                    }

                VStack(spacing: AppTheme.Spacing.md) {
                    Text("No Contacts in Group")
                        .font(AppTheme.Typography.title2)
                        .foregroundColor(.primary)

                    Text("Add contacts to this group to organize them together")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                showingAddContacts = true
            } label: {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "person.badge.plus")
                        .font(.title3)
                    Text("Add Contacts")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

struct AddContactsToGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    let group: ContactGroup
    @State private var searchText = ""
    @State private var selectedContacts: Set<Contact> = []

    private var availableContacts: [Contact] {
        let groupContactIDs = Set((group.contacts?.allObjects as? [Contact])?.map { $0.objectID } ?? [])
        return contactManager.contacts.filter { contact in
            let matchesSearch = searchText.isEmpty ||
                contact.firstName?.localizedCaseInsensitiveContains(searchText) == true ||
                contact.lastName?.localizedCaseInsensitiveContains(searchText) == true ||
                contact.phoneNumber?.localizedCaseInsensitiveContains(searchText) == true

            return !groupContactIDs.contains(contact.objectID) && matchesSearch
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if availableContacts.isEmpty {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        IconBadge("person.2.slash", color: AppTheme.accent, size: 80)

                        Text(searchText.isEmpty ? "All contacts are already in this group" : "No contacts found")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(availableContacts, id: \.objectID) { contact in
                                SelectableContactRowView(
                                    contact: contact,
                                    isSelected: selectedContacts.contains(contact)
                                ) {
                                    if selectedContacts.contains(contact) {
                                        selectedContacts.remove(contact)
                                    } else {
                                        selectedContacts.insert(contact)
                                    }
                                }
                                .padding(.horizontal, AppTheme.Spacing.lg)
                            }
                        }
                        .padding(.top, AppTheme.Spacing.sm)
                    }
                    .background(AppTheme.background)
                }
            }
            .searchable(text: $searchText, prompt: "Search...")
            .navigationTitle("Add to \(group.name ?? "Group")")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedContacts.count))") {
                        addSelectedContacts()
                    }
                    .disabled(selectedContacts.isEmpty)
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
        }
    }

    private func addSelectedContacts() {
        for contact in selectedContacts {
            contactManager.addContactToGroup(contact, group: group)
        }
        dismiss()
    }
}

struct SelectableContactRowView: View {
    let contact: Contact
    let isSelected: Bool
    let onToggle: () -> Void
    @State private var isPressed = false

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

    var body: some View {
        HStack(spacing: AppTheme.Spacing.lg) {
            // Modern Avatar
            IconBadge("person.fill", color: avatarColor, size: 48)
                .overlay(
                    Text(initials)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(contactName)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(contact.phoneNumber ?? "No phone")
                    .font(AppTheme.Typography.callout)
                    .foregroundColor(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            // Modern selection indicator
            Button {
                onToggle()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.secondaryText)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(AppAnimations.bouncy, value: isPressed)
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                .fill(isSelected ? AppTheme.accent.opacity(0.1) : AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .stroke(isSelected ? AppTheme.accent.opacity(0.3) : Color.clear, lineWidth: 2)
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(AppAnimations.spring) {
                isPressed = true
                onToggle()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppAnimations.spring) {
                    isPressed = false
                }
            }
        }
        .animation(AppAnimations.spring, value: isSelected)
        .animation(AppAnimations.spring, value: isPressed)
    }
}

struct EditContactGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    let group: ContactGroup
    @Binding var isEditing: Bool

    @State private var groupName: String = ""
    @State private var selectedColor = Color.blue

    private let availableColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .yellow, .mint
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Group Icon Preview
                    Circle()
                        .fill(selectedColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 36))
                                .foregroundColor(selectedColor)
                        }

                    Text("Edit Group")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                VStack(spacing: AppTheme.Spacing.lg) {
                    // Group Name Input
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Enter group name", text: $groupName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }

                    // Color Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Group Color")
                            .font(.headline)
                            .foregroundColor(.primary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(availableColors.indices, id: \.self) { index in
                                let color = availableColors[index]

                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.headline)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }

                Spacer()

                // Save Button
                Button {
                    saveChanges()
                } label: {
                    Text("Save Changes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .navigationTitle("Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isEditing = false
                    }
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }

    private func setupInitialValues() {
        groupName = group.name ?? ""
        if let colorHex = group.colorHex {
            selectedColor = Color(hex: colorHex)
        }
    }

    private func saveChanges() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        group.name = trimmedName
        group.colorHex = selectedColor.toHex()

        do {
            try contactManager.saveContext()
        } catch {
            print("Error updating group: \(error)")
        }

        isEditing = false
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        let contacts = (1...2).map { i in
            PreviewSeed.contact(ctx, firstName: "Col\(i)", lastName: "League", phone: "+1555400\(i)")
        }
        _ = PreviewSeed.group(ctx, name: "Colleagues", colorHex: "#32D74B", contacts: contacts)
    }
    return ContactGroupDetailView(group: env.contactManager.contactGroups.first!)
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
