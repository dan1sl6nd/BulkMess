import Foundation
@preconcurrency import Contacts
import CoreData

class ContactManager: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var contactGroups: [ContactGroup] = []
    @Published var permissionStatus: CNAuthorizationStatus = .notDetermined

    private let contactStore = CNContactStore()
    private let persistenceController: PersistenceController

    init(persistenceController: PersistenceController = .shared) {
        self.persistenceController = persistenceController
        checkContactsPermission()
        loadContacts()
        loadContactGroups()
    }

    // MARK: - Permission Management

    func checkContactsPermission() {
        permissionStatus = CNContactStore.authorizationStatus(for: .contacts)
    }

    func requestContactsPermission() async -> Bool {
        do {
            let granted = try await contactStore.requestAccess(for: .contacts)
            await MainActor.run {
                self.permissionStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            await MainActor.run {
                self.permissionStatus = .denied
            }
            return false
        }
    }

    // MARK: - Device Contacts Import

    func importDeviceContacts() async throws {
        guard permissionStatus == .authorized || permissionStatus == .limited else {
            throw ContactError.permissionDenied
        }

        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey, CNContactIdentifierKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)

        // Move heavy contact enumeration to background queue
        let deviceContacts = try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    var contacts: [CNContact] = []
                    try self.contactStore.enumerateContacts(with: request) { contact, stop in
                        contacts.append(contact)
                    }
                    continuation.resume(returning: contacts)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }

        try await saveDeviceContactsToCoreData(deviceContacts)
    }

    private func saveDeviceContactsToCoreData(_ cnContacts: [CNContact]) async throws {
        // Use background context to avoid blocking main thread
        let backgroundContext = persistenceController.container.newBackgroundContext()

        try await backgroundContext.perform {
            // Batch fetch existing contacts to avoid individual queries
            let existingContactsRequest: NSFetchRequest<Contact> = Contact.fetchRequest()
            existingContactsRequest.predicate = NSPredicate(format: "deviceContactIdentifier != nil")

            let existingContacts = try backgroundContext.fetch(existingContactsRequest)
            let existingContactsDict = Dictionary(grouping: existingContacts) { $0.deviceContactIdentifier }

            // Process contacts in batches to improve performance
            let batchSize = 100
            var processedCount = 0

            for batch in cnContacts.chunked(into: batchSize) {
                for cnContact in batch {
                    guard let phoneNumber = cnContact.phoneNumbers.first?.value.stringValue,
                          !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        continue
                    }

                    if let existingContact = existingContactsDict[cnContact.identifier]?.first {
                        // Update existing contact
                        existingContact.firstName = cnContact.givenName.isEmpty ? nil : cnContact.givenName
                        existingContact.lastName = cnContact.familyName.isEmpty ? nil : cnContact.familyName
                        existingContact.phoneNumber = phoneNumber
                        existingContact.email = cnContact.emailAddresses.first?.value as String?
                    } else {
                        // Create new contact
                        let contact = Contact(context: backgroundContext)
                        contact.firstName = cnContact.givenName.isEmpty ? nil : cnContact.givenName
                        contact.lastName = cnContact.familyName.isEmpty ? nil : cnContact.familyName
                        contact.phoneNumber = phoneNumber
                        contact.email = cnContact.emailAddresses.first?.value as String?
                        contact.dateCreated = Date()
                        contact.isFromDeviceContacts = true
                        contact.deviceContactIdentifier = cnContact.identifier
                    }
                }

                processedCount += batch.count

                // Save periodically to avoid memory buildup
                if processedCount % (batchSize * 5) == 0 {
                    do {
                        try backgroundContext.save()
                    } catch {
                        print("Error during periodic save: \(error)")
                        // Continue processing even if periodic save fails
                    }
                }
            }

            // Final save
            try backgroundContext.save()
        }

        // Reload contacts on main thread
        await MainActor.run {
            loadContacts()
        }
    }

    // MARK: - Manual Contact Management

    func addContact(firstName: String?, lastName: String?, phoneNumber: String, email: String?, notes: String?) throws {
        guard !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ContactError.invalidPhoneNumber
        }

        let context = persistenceController.container.viewContext

        let contact = Contact(context: context)
        contact.firstName = firstName?.isEmpty == true ? nil : firstName
        contact.lastName = lastName?.isEmpty == true ? nil : lastName
        contact.phoneNumber = phoneNumber
        contact.email = email?.isEmpty == true ? nil : email
        contact.notes = notes?.isEmpty == true ? nil : notes
        contact.dateCreated = Date()
        contact.isFromDeviceContacts = false

        do {
            try context.save()
            loadContacts()
        } catch {
            print("Error adding contact: \(error)")
            throw ContactError.saveFailed(error.localizedDescription)
        }
    }

    func updateContact(_ contact: Contact, firstName: String?, lastName: String?, phoneNumber: String, email: String?, notes: String?) {
        contact.firstName = firstName?.isEmpty == true ? nil : firstName
        contact.lastName = lastName?.isEmpty == true ? nil : lastName
        contact.phoneNumber = phoneNumber
        contact.email = email?.isEmpty == true ? nil : email
        contact.notes = notes?.isEmpty == true ? nil : notes

        do {
            try persistenceController.container.viewContext.save()
            loadContacts()
        } catch {
            print("Error updating contact: \(error)")
        }
    }

    func deleteContact(_ contact: Contact) {
        let context = persistenceController.container.viewContext
        context.delete(contact)

        do {
            try context.save()
            loadContacts()
        } catch {
            print("Error deleting contact: \(error)")
        }
    }

    // MARK: - Contact Group Management

    func createContactGroup(name: String, colorHex: String? = nil) {
        let context = persistenceController.container.viewContext

        let group = ContactGroup(context: context)
        group.name = name
        group.dateCreated = Date()
        group.colorHex = colorHex

        do {
            try context.save()
            loadContactGroups()
            print("Created contact group: \(name). Total groups: \(contactGroups.count)")
            // Trigger UI update
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            print("Error creating contact group: \(error)")
        }
    }

    func addContactToGroup(_ contact: Contact, group: ContactGroup) {
        contact.addToGroups(group)

        do {
            try persistenceController.container.viewContext.save()
            // Trigger UI update
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            print("Error adding contact to group: \(error)")
        }
    }

    func removeContactFromGroup(_ contact: Contact, group: ContactGroup) {
        contact.removeFromGroups(group)

        do {
            try persistenceController.container.viewContext.save()
            // Trigger UI update
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        } catch {
            print("Error removing contact from group: \(error)")
        }
    }

    func deleteContactGroup(_ group: ContactGroup) {
        let context = persistenceController.container.viewContext
        context.delete(group)

        do {
            try context.save()
            loadContactGroups()
        } catch {
            print("Error deleting contact group: \(error)")
        }
    }

    func saveContext() throws {
        let context = persistenceController.container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    func reloadContactGroups() {
        loadContactGroups()
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }

    // MARK: - Data Loading

    private func loadContacts() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<Contact> = Contact.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Contact.firstName, ascending: true)]

        do {
            contacts = try context.fetch(request)
        } catch {
            print("Error loading contacts: \(error)")
        }
    }

    private func loadContactGroups() {
        let context = persistenceController.container.viewContext
        let request: NSFetchRequest<ContactGroup> = ContactGroup.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ContactGroup.name, ascending: true)]

        do {
            contactGroups = try context.fetch(request)
        } catch {
            print("Error loading contact groups: \(error)")
        }
    }

    // MARK: - Utility Methods

    func getFormattedContactName(_ contact: Contact) -> String {
        let firstName = contact.firstName ?? ""
        let lastName = contact.lastName ?? ""

        if firstName.isEmpty && lastName.isEmpty {
            return contact.phoneNumber ?? "No Phone"
        } else if firstName.isEmpty {
            return lastName
        } else if lastName.isEmpty {
            return firstName
        } else {
            return "\(firstName) \(lastName)"
        }
    }

    func searchContacts(_ searchText: String) -> [Contact] {
        if searchText.isEmpty {
            return contacts
        }

        return contacts.filter { contact in
            let name = getFormattedContactName(contact).lowercased()
            let phone = (contact.phoneNumber ?? "").lowercased()
            let email = contact.email?.lowercased() ?? ""

            return name.contains(searchText.lowercased()) ||
                   phone.contains(searchText.lowercased()) ||
                   email.contains(searchText.lowercased())
        }
    }
}

enum ContactError: Error, LocalizedError {
    case permissionDenied
    case importFailed
    case invalidPhoneNumber
    case saveFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Contacts permission denied. Please enable contacts access in Settings."
        case .importFailed:
            return "Failed to import contacts from device."
        case .invalidPhoneNumber:
            return "Phone number is required and cannot be empty."
        case .saveFailed(let details):
            return "Failed to save contact: \(details)"
        }
    }
}