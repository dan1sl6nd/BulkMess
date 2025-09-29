import SwiftUI
import UIKit

// MARK: - UIKit Text View Wrapper for Cursor Position

struct CursorAwareTextEditor: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let onCursorPositionChange: (Int) -> Void

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.backgroundColor = UIColor.clear
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        // Set initial text
        textView.text = text

        // Store reference in coordinator
        context.coordinator.textView = textView

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update if text actually differs to prevent loops
        if uiView.text != text {
            // Calculate where the cursor should be after text changes
            let oldLength = uiView.text.count
            let newLength = text.count
            let currentPosition = uiView.selectedRange.location

            uiView.text = text

            // If text got longer, likely due to insertion, move cursor to end of new content
            if newLength > oldLength {
                let insertionLength = newLength - oldLength
                let newPosition = min(currentPosition + insertionLength, text.count)
                uiView.selectedRange = NSRange(location: newPosition, length: 0)
            } else {
                // Try to maintain cursor position, but ensure it's valid
                let newPosition = min(currentPosition, text.count)
                uiView.selectedRange = NSRange(location: newPosition, length: 0)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        let parent: CursorAwareTextEditor
        private var isUpdatingFromParent = false
        weak var textView: UITextView?

        init(_ parent: CursorAwareTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !isUpdatingFromParent else { return }
            // Update text immediately to keep binding in sync
            parent.text = textView.text
            updateCursorPosition(textView)
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isUpdatingFromParent else { return }
            updateCursorPosition(textView)
        }

        private func updateCursorPosition(_ textView: UITextView) {
            let position = textView.selectedRange.location
            // The callback will handle async dispatch to avoid state update during view cycle
            parent.onCursorPositionChange(position)
        }

        // Method to programmatically set cursor position
        func setCursorPosition(_ position: Int) {
            guard let textView = textView else { return }
            let safePosition = min(position, textView.text.count)
            textView.selectedRange = NSRange(location: safePosition, length: 0)
        }
    }

    // Method to insert text at cursor position
    func insertText(_ insertText: String, at position: Int) {
        let index = text.index(text.startIndex, offsetBy: min(position, text.count))
        text.insert(contentsOf: insertText, at: index)
    }
}

// MARK: - Enhanced Text Editor Component

struct EnhancedTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let characterCount: Int
    @State private var cursorPosition: Int = 0

    // Method to insert text at cursor position
    func insertTextAtCursor(_ insertText: String) {
        let position = min(cursorPosition, text.count)
        let index = text.index(text.startIndex, offsetBy: position)
        text.insert(contentsOf: insertText, at: index)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "text.alignleft")
                    .font(.title3)
                    .foregroundColor(AppTheme.accent)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(AppTheme.secondaryText)
                            .font(AppTheme.Typography.body)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.md + 2)
                    }

                    CursorAwareTextEditor(
                        text: $text,
                        placeholder: placeholder,
                        onCursorPositionChange: { position in
                            DispatchQueue.main.async {
                                cursorPosition = position
                            }
                        }
                    )
                    .frame(minHeight: 120)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(AppTheme.accent.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )

                HStack {
                    Spacer()
                    Text("\(characterCount) characters")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }
}

// MARK: - Alternative Simple Solution using TextEditor with Range

struct SmartTextEditor: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    let characterCount: Int

    // This is the insertion method that can be called from parent
    func insertTextAtCursor(_ insertText: String) {
        // If we can't get cursor position, append with space
        if text.isEmpty {
            text = insertText
        } else {
            // Add space before if text doesn't end with space
            let needsSpace = !text.hasSuffix(" ") && !text.hasSuffix("\n")
            text += (needsSpace ? " " : "") + insertText
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "text.alignleft")
                    .font(.title3)
                    .foregroundColor(AppTheme.accent)
                Text(title)
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(.primary)
            }

            VStack(spacing: AppTheme.Spacing.xs) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(AppTheme.secondaryText)
                            .font(AppTheme.Typography.body)
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.md + 2)
                    }

                    TextEditor(text: $text)
                        .font(AppTheme.Typography.body)
                        .padding(AppTheme.Spacing.md)
                        .frame(minHeight: 120)
                        .background(Color.clear)
                }
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                        .fill(AppTheme.accent.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                                .stroke(AppTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                )

                HStack {
                    Spacer()
                    Text("\(characterCount) characters")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.secondaryText)
                }
            }
        }
    }
}