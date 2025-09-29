//
//  ContentView.swift
//  BulkMess
//
//  Created by Daniil Mukashev on 13/09/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

#Preview {
    let env = PreviewEnvironment.make { ctx in
        _ = PreviewSeed.contact(ctx, firstName: "Alex", lastName: "Johnson", phone: "+15551234567")
        _ = PreviewSeed.template(ctx, name: "Hello", content: "Hi {{firstName}}!")
    }
    return ContentView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
        .environmentObject(env.templateManager)
        .environmentObject(env.campaignManager)
}
