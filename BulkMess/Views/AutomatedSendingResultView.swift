import SwiftUI

struct AutomatedSendingResultView: View {
    let result: AutomatedSendingResult?
    let onDismiss: () -> Void
    let onRetryFailed: (() -> Void)?

    init(result: AutomatedSendingResult?, onDismiss: @escaping () -> Void, onRetryFailed: (() -> Void)? = nil) {
        self.result = result
        self.onDismiss = onDismiss
        self.onRetryFailed = onRetryFailed
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                if let result = result {
                    // Success Icon
                    Image(systemName: result.totalFailed == 0 ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(result.totalFailed == 0 ? .green : .orange)

                    // Title
                    Text(result.totalFailed == 0 ? "Sending Complete!" : "Sending Completed with Issues")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // Summary Stats
                    VStack(spacing: AppTheme.Spacing.lg) {
                        ResultStatRow(
                            title: "Messages Sent",
                            value: "\(result.totalSent)",
                            color: .green,
                            icon: "checkmark.circle.fill"
                        )

                        if result.totalFailed > 0 {
                            ResultStatRow(
                                title: "Failed to Send",
                                value: "\(result.totalFailed)",
                                color: .red,
                                icon: "xmark.circle.fill"
                            )
                        }

                        ResultStatRow(
                            title: "Success Rate",
                            value: "\(Int(result.successRate))%",
                            color: result.successRate >= 90 ? .green : result.successRate >= 70 ? .orange : .red,
                            icon: "chart.bar.fill"
                        )

                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.blue)
                            Text("Completed at \(result.completionTime, formatter: timeFormatter)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                    .padding(.horizontal)

                    // Error Details (if any)
                    if !result.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Error Details")
                                    .font(.headline)
                                Spacer()
                            }

                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 8) {
                                    ForEach(result.errors, id: \.self) { error in
                                        HStack {
                                            Image(systemName: "xmark.circle")
                                                .foregroundColor(.red)
                                                .font(.caption)
                                            Text(error)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 4)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .frame(maxHeight: 150)
                        }
                        .padding(.horizontal)
                    }

                    // Recommendations
                    if result.successRate < 90 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.blue)
                                Text("Recommendations")
                                    .font(.headline)
                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                if result.totalFailed > 0 {
                                    Text("• Check phone number formats")
                                    Text("• Verify network connectivity")
                                    Text("• Try smaller batch sizes")
                                }
                                if result.successRate < 70 {
                                    Text("• Consider manual review of failed contacts")
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }

                    Spacer()

                    // Action Buttons
                    VStack(spacing: AppTheme.Spacing.md) {
                        Button("Done") {
                            onDismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity)

                        if result.totalFailed > 0, let onRetryFailed = onRetryFailed {
                            Button("Retry Failed Messages") {
                                onRetryFailed()
                                onDismiss()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)

                } else {
                    ProgressView("Processing results...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .padding()
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

struct ResultStatRow: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    let sampleResult = AutomatedSendingResult(
        totalSent: 95,
        totalFailed: 5,
        errors: [
            "Failed to send to +1234567890",
            "Failed to send to +0987654321",
            "Failed to send to +1122334455"
        ],
        completionTime: Date()
    )

    return AutomatedSendingResultView(
        result: sampleResult,
        onDismiss: {}
    )
}
