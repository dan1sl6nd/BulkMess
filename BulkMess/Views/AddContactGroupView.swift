import SwiftUI

struct AddContactGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var contactManager: ContactManager

    @State private var groupName = ""
    @State private var selectedColor = Color.blue

    private let availableColors: [Color] = [
        .blue, .green, .orange, .purple, .pink, .red, .indigo, .teal, .yellow, .mint
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                VStack(spacing: AppTheme.Spacing.lg) {
                    // Group Icon Preview
                    Circle()
                        .fill(selectedColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 36))
                                .foregroundColor(selectedColor)
                        }

                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("New Contact Group")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("Create a group to organize your contacts")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }

                VStack(spacing: AppTheme.Spacing.lg) {
                    // Group Name Input
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(.primary)

                        TextField("Enter group name", text: $groupName)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                    }

                    // Color Selection
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Group Color")
                            .font(.headline)
                            .foregroundColor(.primary)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(availableColors.indices, id: \.self) { index in
                                let color = availableColors[index]

                                Circle()
                                    .fill(color)
                                    .frame(width: 44, height: 44)
                                    .overlay {
                                        if selectedColor == color {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(.white)
                                                .font(.headline)
                                                .fontWeight(.bold)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }

                Spacer()

                // Create Button
                Button {
                    createGroup()
                } label: {
                    Text("Create Group")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Convert Color to hex string
        let colorHex = selectedColor.toHex()

        contactManager.createContactGroup(name: trimmedName, colorHex: colorHex)
        dismiss()
    }
}


#Preview {
    let env = PreviewEnvironment.make()
    return AddContactGroupView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
