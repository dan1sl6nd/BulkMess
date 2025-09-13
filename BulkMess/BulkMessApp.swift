//
//  BulkMessApp.swift
//  BulkMess
//
//  Created by Daniil Mukashev on 13/09/2025.
//

import SwiftUI

@main
struct BulkMessApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
