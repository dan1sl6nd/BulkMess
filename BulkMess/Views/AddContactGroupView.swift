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
            ScrollView {
                LazyVStack(spacing: AppTheme.Spacing.xl) {
                    // Preview Card
                    SectionCard(title: "Group Preview", subtitle: "See how your group will look") {
                        HStack(spacing: AppTheme.Spacing.lg) {
                            // Group Icon Preview
                            IconBadge("folder.fill", color: selectedColor, size: 80)

                            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                                Text(groupName.isEmpty ? "Group Name" : groupName)
                                    .font(AppTheme.Typography.title2)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)

                                Text("0 contacts")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(AppTheme.secondaryText)
                            }

                            Spacer()
                        }
                    }

                    // Group Information Card
                    SectionCard(title: "Group Information", subtitle: "Give your group a descriptive name") {
                        ModernTextField(
                            title: "Group Name",
                            text: $groupName,
                            placeholder: "Team Members",
                            icon: "folder.fill"
                        )
                    }

                    // Color Selection Card
                    SectionCard(title: "Group Color", subtitle: "Choose a color to identify this group") {
                        ColorPickerGrid(
                            availableColors: availableColors,
                            selectedColor: $selectedColor
                        )
                    }

                    // Save Button
                    if isValidGroup {
                        Button {
                            createGroup()
                        } label: {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Create Group")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, AppTheme.Spacing.lg)
                    }
                }
                .padding(.horizontal, AppTheme.Spacing.lg)
                .padding(.top, AppTheme.Spacing.sm)
            }
            .background(AppTheme.background)
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        createGroup()
                    }
                    .disabled(!isValidGroup)
                }
            }
        }
    }

    private var isValidGroup: Bool {
        !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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

// MARK: - Color Picker Grid Component

struct ColorPickerGrid: View {
    let availableColors: [Color]
    @Binding var selectedColor: Color

    private let columns: [GridItem] = Array(repeating: GridItem(.flexible()), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: AppTheme.Spacing.md) {
            ForEach(availableColors.indices, id: \.self) { index in
                ColorCircleButton(
                    color: availableColors[index],
                    isSelected: selectedColor == availableColors[index]
                ) {
                    withAnimation(AppAnimations.spring) {
                        selectedColor = availableColors[index]
                    }
                }
            }
        }
    }
}

struct ColorCircleButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 50, height: 50)

                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 3)
                        .padding(2)

                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 4)
                        .padding(-2)

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 22))
                        .shadow(color: Color.black.opacity(0.2), radius: 2)
                }
            }
            .scaleEffect(isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let env = PreviewEnvironment.make()
    return AddContactGroupView()
        .environment(\.managedObjectContext, env.ctx)
        .environmentObject(env.contactManager)
}
