import SwiftUI

struct ShortcutsSetupView: View {
    @EnvironmentObject var deliverySettings: DeliverySettings

    @State private var toastMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Set Up ‘\(deliverySettings.shortcutName)’ Shortcut")
                    .font(.title2)
                    .fontWeight(.semibold)

                setupSteps

                HStack(spacing: AppTheme.Spacing.md) {
                    Button {
                        copySamplePayload()
                        toast("Sample payload copied to clipboard")
                    } label: {
                        Label("Copy Sample Payload", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        openShortcutsApp()
                    } label: {
                        Label("Open Shortcuts", systemImage: "app")
                    }
                    .buttonStyle(.borderedProminent)
                }

                samplePayloadView
            }
            .padding()
            .overlay(alignment: .top) {
                if let text = toastMessage {
                    ToastBanner(text: text)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.25), value: toastMessage)
                }
            }
        }
        .navigationTitle("Shortcuts Setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var setupSteps: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Create a Shortcut named ‘\(deliverySettings.shortcutName)’ with these actions:")
                .font(.headline)

            Group {
                step(1, "Open Shortcuts → Create Shortcut")
                step(2, "Add ‘Get Contents of Clipboard’")
                step(3, "Add ‘Repeat with Each’ and select the Clipboard variable as the list to repeat")
                step(4, "Inside the Repeat:")
                bullet("Add ‘Send Message’")
                bullet("Message: use the Repeat Item’s ‘body’ field")
                bullet("Recipients: use the Repeat Item’s ‘phone’ field")
                step(5, "Name the shortcut exactly: ‘\(deliverySettings.shortcutName)’")
            }
            .font(.subheadline)
        }
    }

    private func step(_ number: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number).")
                .bold()
            Text(text)
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }

    private var samplePayload: String {
        """
        [
          {"phone": "+15551234567", "body": "Hello Jane!"},
          {"phone": "+15557654321", "body": "Hello John!"}
        ]
        """
    }

    private var samplePayloadView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sample Payload")
                .font(.headline)
            Text(samplePayload)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }

    private func copySamplePayload() {
        UIPasteboard.general.string = samplePayload
    }

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }

    private func toast(_ text: String) {
        toastMessage = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { toastMessage = nil }
        }
    }
}

#Preview {
    let env = PreviewEnvironment.make()
    return NavigationStack { ShortcutsSetupView() }
        .environmentObject(env.deliverySettings)
}
