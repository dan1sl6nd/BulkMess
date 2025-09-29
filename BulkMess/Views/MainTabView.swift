import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var contactManager: ContactManager
    @EnvironmentObject var templateManager: MessageTemplateManager
    @EnvironmentObject var campaignManager: CampaignManager
    @Environment(\.scenePhase) private var scenePhase


    var body: some View {
        TabView {
            ContactsView()
                .tabItem {
                    Label("Contacts", systemImage: "person.2.fill")
                }

            TemplatesView()
                .tabItem {
                    Label("Templates", systemImage: "doc.text.fill")
                }

            CampaignsView()
                .tabItem {
                    Label("Campaigns", systemImage: "megaphone.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(AppTheme.accent)
        .background(AppTheme.background)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

