import SwiftUI

struct ShortcutsAutoSetupView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "magic.wand")
                                .foregroundColor(.blue)
                            Text("Shortcuts Setup")
                                .font(.headline)
                        }

                        Text("Create iOS Shortcuts for automated message sending")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Button {
                            openShortcutsApp()
                        } label: {
                            HStack {
                                Image(systemName: "shortcuts")
                                Text("Open iOS Shortcuts App")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 8)
                }

                Section("Manual Setup Required") {
                    Text("Due to iOS limitations, shortcuts must be created manually in the Shortcuts app. Please refer to the documentation for detailed instructions.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Shortcuts Setup")
        }
    }

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }
}

#Preview {
    ShortcutsAutoSetupView()
}