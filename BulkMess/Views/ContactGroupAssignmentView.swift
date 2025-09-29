import SwiftUI

struct ContactGroupAssignmentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    let contact: Contact
    @State private var showingAddGroup = false
    @State private var selectedGroups: Set<ObjectIdentifier> = []

    private var contactGroups: [ContactGroup] {
        (contact.groups?.allObjects as? [ContactGroup]) ?? []
    }

    var body: some View {
        NavigationStack {
            VStack {
                if contactManager.contactGroups.isEmpty {
                    NoGroupsAvailableView(showingAddGroup: $showingAddGroup)
                } else {
                    List {
                        Section {
                            ForEach(contactManager.contactGroups, id: \.objectID) { group in
                                GroupToggleRowView(
                                    group: group,
                                    isSelected: selectedGroups.contains(ObjectIdentifier(group))
                                ) {
                                    toggleGroupMembership(group)
                                }
                            }
                        } header: {
                            Text("Available Groups")
                        } footer: {
                            Text("Toggle groups to add or remove this contact")
                        }
                    }
                }
            }
            .navigationTitle("Manage Groups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
            .onAppear {
                initializeSelectedGroups()
            }
        }
    }

    private func initializeSelectedGroups() {
        selectedGroups = Set(contactGroups.map { ObjectIdentifier($0) })
    }

    private func toggleGroupMembership(_ group: ContactGroup) {
        let groupId = ObjectIdentifier(group)

        if selectedGroups.contains(groupId) {
            // Remove from group
            selectedGroups.remove(groupId)
            contactManager.removeContactFromGroup(contact, group: group)
            print("Removed contact from group: \(group.name ?? "Unknown")")
        } else {
            // Add to group
            selectedGroups.insert(groupId)
            contactManager.addContactToGroup(contact, group: group)
            print("Added contact to group: \(group.name ?? "Unknown")")
        }

        // Force refresh the contact groups after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            contact.managedObjectContext?.refresh(contact, mergeChanges: true)
        }
    }
}

struct GroupToggleRowView: View {
    let group: ContactGroup
    let isSelected: Bool
    let onToggle: () -> Void

    private var groupColor: Color {
        if let colorHex = group.colorHex {
            return Color(hex: colorHex)
        }
        return .blue
    }

    var body: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            // Group Icon
            Circle()
                .fill(groupColor.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "folder.fill")
                        .foregroundColor(groupColor)
                        .font(.title3)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name ?? "Unnamed Group")
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(group.contacts?.count ?? 0) contacts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Toggle Button
            Button {
                onToggle()
            } label: {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }
}

struct NoGroupsAvailableView: View {
    @Binding var showingAddGroup: Bool

    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            VStack(spacing: AppTheme.Spacing.lg) {
                Image(systemName: "folder.badge.gearshape")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)

                VStack(spacing: AppTheme.Spacing.sm) {
                    Text("No Groups Available")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Create your first contact group to organize this contact")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            Button {
                showingAddGroup = true
            } label: {
                Label("Create First Group", systemImage: "folder.fill.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(.horizontal, AppTheme.Spacing.xxl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.group(ctx, name: "Leads", colorHex: "#0A84FF")
        _ = PreviewSeed.group(ctx, name: "Clients", colorHex: "#FF9F0A")
        _ = PreviewSeed.contact(ctx, firstName: "Olivia", lastName: "Gray", phone: "+15551212")
    }
    return ContactGroupAssignmentView(contact: env.contactManager.contacts.first!)
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
