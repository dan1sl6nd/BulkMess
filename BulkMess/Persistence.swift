//
//  Persistence.swift
//  BulkMess
//
//  Created by Daniil Mukashev on 13/09/2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Create sample data for preview
        let sampleContact = Contact(context: viewContext)
        sampleContact.firstName = "John"
        sampleContact.lastName = "Doe"
        sampleContact.phoneNumber = "+1234567890"
        sampleContact.email = "john.doe@example.com"
        sampleContact.dateCreated = Date()
        sampleContact.isFromDeviceContacts = false

        let sampleTemplate = MessageTemplate(context: viewContext)
        sampleTemplate.name = "Welcome Message"
        sampleTemplate.content = "Hello {{firstName}}, welcome to our service!"
        sampleTemplate.dateCreated = Date()
        sampleTemplate.dateModified = Date()
        sampleTemplate.isFavorite = false
        sampleTemplate.usageCount = 0

        do {
            try viewContext.save()
        } catch {
            // Handle preview data creation errors gracefully
            print("Warning: Failed to create preview data: \(error.localizedDescription)")
            // For preview, we can continue without sample data
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "BulkMess")
        if inMemory {
            guard let firstStoreDescription = container.persistentStoreDescriptions.first else {
                print("Warning: No persistent store descriptions found for in-memory configuration")
                return
            }
            firstStoreDescription.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { [weak container] (storeDescription, error) in
            if let error = error as NSError? {
                // Handle Core Data loading errors gracefully
                print("Core Data Error: Failed to load persistent store - \(error.localizedDescription)")
                print("Error details: \(error.userInfo)")

                // In case of corruption, attempt to recreate the store
                if error.code == NSPersistentStoreIncompatibleVersionHashError ||
                   error.code == NSMigrationMissingSourceModelError ||
                   error.code == NSPersistentStoreIncompatibleSchemaError {

                    print("Attempting to recreate corrupted Core Data store...")
                    PersistenceController.recreatePersistentStore(for: container)
                }
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        // Configure merge policy for better conflict resolution
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Error Recovery

    private static func recreatePersistentStore(for container: NSPersistentContainer?) {
        guard let container = container,
              let storeURL = container.persistentStoreDescriptions.first?.url else {
            print("No container or store URL found for recreation")
            return
        }

        do {
            // Remove the corrupted store file
            try FileManager.default.removeItem(at: storeURL)

            // Remove related files (WAL, SHM)
            let walURL = storeURL.appendingPathExtension("wal")
            let shmURL = storeURL.appendingPathExtension("shm")
            try? FileManager.default.removeItem(at: walURL)
            try? FileManager.default.removeItem(at: shmURL)

            print("Removed corrupted store files")

            // Recreate the store
            try container.persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: nil
            )

            print("Successfully recreated Core Data store")

        } catch {
            print("Failed to recreate persistent store: \(error)")
            // At this point, we could show an alert to the user
            // or implement a fallback to in-memory storage
        }
    }

    // MARK: - Background Context Management

    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
