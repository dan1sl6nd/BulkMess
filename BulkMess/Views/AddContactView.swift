import SwiftUI

struct AddContactView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var errorHandler: ErrorHandler

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var phoneNumber = ""
    @State private var email = ""
    @State private var notes = ""

    @State private var showingValidationAlert = false
    @State private var validationMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Contact Information")) {
                    TextField("First Name", text: $firstName)
                    TextField("Last Name", text: $lastName)
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email (Optional)", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }

                Section(header: Text("Notes")) {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveContact()
                    }
                    .disabled(!isValidContact)
                }
            }
            .alert("Invalid Contact", isPresented: $showingValidationAlert) {
                Button("OK") { }
            } message: {
                Text(validationMessage)
            }
        }
    }

    private var isValidContact: Bool {
        !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveContact() {
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

        do {
            try contactManager.addContact(
                firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : firstName.trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : lastName.trimmingCharacters(in: .whitespacesAndNewlines),
                phoneNumber: trimmedPhoneNumber,
                email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            dismiss()
        } catch {
            if let contactError = error as? ContactError {
                errorHandler.handle(contactError.asAppError)
            } else {
                errorHandler.handle(AppError.unknown(error.localizedDescription))
            }
        }
    }
}

#Preview {
    let env = PreviewEnvironment.make()
    return AddContactView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
