import SwiftUI

struct ShortcutSetupInstructionsView: View {
    let method: AutomatedSendingView.SendingMethod
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bulkService = BulkAutomatedMessagingService()

    var automatedMethod: AutomatedSendingMethod {
        switch method {
        case .autoSend:
            return .autoSend
        case .batchProcessor:
            return .batchProcessor(batchSize: 10, delaySeconds: 2)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xl) {
                    // Header
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        HStack {
                            Image(systemName: method.icon)
                                .foregroundColor(.blue)
                                .font(.title2)
                            Text("Setup \(method.rawValue) Shortcut")
                                .font(.title2)
                                .fontWeight(.semibold)
                        }

                        Text("Create an iOS Shortcut to enable automated bulk message sending")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    // Quick Setup Button
                    VStack(spacing: AppTheme.Spacing.md) {
                        Button {
                            openShortcutsApp()
                        } label: {
                            HStack {
                                Image(systemName: "shortcuts")
                                    .foregroundColor(.white)
                                Text("Open Shortcuts App")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        Text("This will open the iOS Shortcuts app where you can create the required shortcut")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Step-by-step Instructions
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                        Text("Step-by-Step Instructions")
                            .font(.headline)
                            .fontWeight(.semibold)

                        ForEach(Array(bulkService.getShortcutInstructions(for: automatedMethod).enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: AppTheme.Spacing.md) {
                                Text("\(index + 1)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 20, height: 20)
                                    .background(Color.blue)
                                    .cornerRadius(10)

                                Text(instruction)
                                    .font(.subheadline)
                                    .foregroundColor(.primary)

                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Shortcut Template
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Shortcut Template")
                            .font(.headline)
                            .fontWeight(.semibold)

                        ScrollView(.horizontal, showsIndicators: false) {
                            Text(bulkService.exportShortcutTemplate(for: automatedMethod))
                                .font(.system(.caption, design: .monospaced))
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }

                        Button {
                            copyTemplateToClipboard()
                        } label: {
                            HStack {
                                Image(systemName: "doc.on.clipboard")
                                Text("Copy Template to Clipboard")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }

                    // Important Notes
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Label("Important Notes", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• The shortcut name must match exactly: '\(getShortcutName())'")
                            Text("• Enable 'Allow Running Scripts' in iOS Settings → Shortcuts → Advanced")
                            Text("• Turn OFF 'Ask Before Running' in the shortcut settings")
                            Text("• The shortcut will read message data from the clipboard")
                            Text("• Test the shortcut with a few messages first")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)

                    // Troubleshooting
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Troubleshooting")
                            .font(.headline)
                            .fontWeight(.semibold)

                        DisclosureGroup("Shortcut not found") {
                            Text("Make sure the shortcut name matches exactly and is saved in the iOS Shortcuts app.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        DisclosureGroup("Messages not sending") {
                            Text("Check that 'Allow Running Scripts' is enabled in iOS Settings → Shortcuts → Advanced.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        DisclosureGroup("Manual approval required") {
                            Text("Turn OFF 'Ask Before Running' in the shortcut's settings (tap the shortcut, then settings icon).")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Shortcut Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func getShortcutName() -> String {
        switch method {
        case .autoSend:
            return "BulkMess Auto Send"
        case .batchProcessor:
            return "BulkMess Batch Processor"
        }
    }

    private func openShortcutsApp() {
        if let url = URL(string: "shortcuts://") {
            UIApplication.shared.open(url)
        }
    }

    private func copyTemplateToClipboard() {
        UIPasteboard.general.string = bulkService.exportShortcutTemplate(for: automatedMethod)
    }
}

#Preview {
    ShortcutSetupInstructionsView(method: .autoSend)
}
