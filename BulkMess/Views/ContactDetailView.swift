import SwiftUI

struct ContactDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    let contact: Contact
    @State private var isEditing = false
    @State private var showingGroupManagement = false

    var body: some View {
        NavigationStack {
            VStack {
                if isEditing {
                    EditContactView(contact: contact, isEditing: $isEditing)
                } else {
                    ContactDetailContentView(contact: contact, showingGroupManagement: $showingGroupManagement)
                }
            }
            .navigationTitle(contactName)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Cancel" : "Edit") {
                        isEditing.toggle()
                    }
                }
            }
            .sheet(isPresented: $showingGroupManagement) {
                ContactGroupAssignmentView(contact: contact)
            }
        }
    }

    private var contactName: String {
        let firstName = contact.firstName ?? ""
        let lastName = contact.lastName ?? ""

        if firstName.isEmpty && lastName.isEmpty {
            return "Contact Details"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }
}

struct ContactDetailContentView: View {
    let contact: Contact
    @Binding var showingGroupManagement: Bool
    @EnvironmentObject var contactManager: ContactManager

    var body: some View {
        List {
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.title2)
                            .fontWeight(.semibold)

                        if contact.isFromDeviceContacts {
                            Label("Device Contact", systemImage: "person.crop.circle.badge.checkmark")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            Section("Contact Information") {
                if let firstName = contact.firstName, !firstName.isEmpty {
                    DetailRow(label: "First Name", value: firstName, icon: "person.fill")
                }

                if let lastName = contact.lastName, !lastName.isEmpty {
                    DetailRow(label: "Last Name", value: lastName, icon: "person.fill")
                }

                DetailRow(label: "Phone Number", value: contact.phoneNumber ?? "", icon: "phone.fill")

                if let email = contact.email, !email.isEmpty {
                    DetailRow(label: "Email", value: email, icon: "envelope.fill")
                }
            }

            if let notes = contact.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .padding(.vertical, 4)
                }
            }

            Section {
                if let groups = contact.groups, groups.count > 0 {
                    ForEach(Array(groups) as! [ContactGroup], id: \.objectID) { group in
                        HStack {
                            Circle()
                                .fill(Color(hex: group.colorHex ?? "#007AFF"))
                                .frame(width: 16, height: 16)

                            Text(group.name ?? "Unknown Group")
                                .font(.subheadline)

                            Spacer()

                            Button {
                                contactManager.removeContactFromGroup(contact, group: group)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Button {
                    showingGroupManagement = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)

                        Text(contact.groups?.count == 0 ? "Add to Group" : "Manage Groups")
                            .foregroundColor(.blue)

                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            } header: {
                Text("Groups (\(contact.groups?.count ?? 0))")
            }

            Section("Metadata") {
                DetailRow(
                    label: "Date Added",
                    value: DateFormatter.shortDate.string(from: contact.dateCreated ?? Date()),
                    icon: "calendar"
                )

                if let messageCount = contact.messages?.count, messageCount > 0 {
                    DetailRow(
                        label: "Messages Sent",
                        value: "\(messageCount)",
                        icon: "message.fill"
                    )
                }
            }
        }
    }

    private var displayName: String {
        let firstName = contact.firstName ?? ""
        let lastName = contact.lastName ?? ""

        if firstName.isEmpty && lastName.isEmpty {
            return contact.phoneNumber ?? "Unknown"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }
}

struct EditContactView: View {
    @EnvironmentObject var contactManager: ContactManager

    let contact: Contact
    @Binding var isEditing: Bool

    @State private var firstName: String
    @State private var lastName: String
    @State private var phoneNumber: String
    @State private var email: String
    @State private var notes: String

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    init(contact: Contact, isEditing: Binding<Bool>) {
        self.contact = contact
        self._isEditing = isEditing

        self._firstName = State(initialValue: contact.firstName ?? "")
        self._lastName = State(initialValue: contact.lastName ?? "")
        self._phoneNumber = State(initialValue: contact.phoneNumber ?? "")
        self._email = State(initialValue: contact.email ?? "")
        self._notes = State(initialValue: contact.notes ?? "")
    }

    var body: some View {
        Form {
            Section("Contact Information") {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                TextField("Email (Optional)", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }

            Section("Notes") {
                TextField("Notes (Optional)", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Button("Save Changes") {
                    saveChanges()
                }
                .foregroundColor(.blue)
            }
        }
        .alert("Invalid Contact", isPresented: $showingValidationAlert) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }

    private func saveChanges() {
        let trimmedPhoneNumber = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedPhoneNumber.isEmpty else {
            validationMessage = "Phone number is required."
            showingValidationAlert = true
            return
        }

        // Basic phone number validation
        let phoneNumberRegex = "^[+]?[0-9\\s\\-\\(\\)]{10,}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneNumberRegex)
        guard phoneTest.evaluate(with: trimmedPhoneNumber) else {
            validationMessage = "Please enter a valid phone number."
            showingValidationAlert = true
            return
        }

        // Email validation if provided
        if !email.isEmpty {
            let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            guard emailTest.evaluate(with: email) else {
                validationMessage = "Please enter a valid email address."
                showingValidationAlert = true
                return
            }
        }

        contactManager.updateContact(
            contact,
            firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : firstName.trimmingCharacters(in: .whitespacesAndNewlines),
            lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : lastName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: trimmedPhoneNumber,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        isEditing = false
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.body)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Extensions

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}


#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.contact(ctx, firstName: "Nora", lastName: "Park", phone: "+15556666", email: "nora@example.com")
    }
    return ContactDetailView(contact: env.contactManager.contacts.first!)
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
