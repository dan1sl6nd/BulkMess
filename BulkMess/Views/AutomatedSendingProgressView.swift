import SwiftUI

struct AutomatedSendingProgressView: View {
    let progress: AutomatedSendingProgress?
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: AppTheme.Spacing.xl) {
                if let progress = progress {
                    // Progress Circle
                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 10)
                            .frame(width: 120, height: 120)

                        Circle()
                            .trim(from: 0, to: progress.progressPercentage / 100)
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: progress.progressPercentage)

                        VStack {
                            Text("\(Int(progress.progressPercentage))%")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Complete")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Status Info
                    VStack(spacing: AppTheme.Spacing.lg) {
                        HStack {
                            ProgressInfoRow(
                                title: "Sent",
                                value: "\(progress.sentCount)",
                                color: .green,
                                icon: "checkmark.circle.fill"
                            )

                            Spacer()

                            ProgressInfoRow(
                                title: "Failed",
                                value: "\(progress.failedCount)",
                                color: .red,
                                icon: "xmark.circle.fill"
                            )

                            Spacer()

                            ProgressInfoRow(
                                title: "Total",
                                value: "\(progress.totalMessages)",
                                color: .blue,
                                icon: "envelope.fill"
                            )
                        }

                        if progress.totalBatches > 1 {
                            HStack {
                                Image(systemName: "square.grid.3x3")
                                    .foregroundColor(.blue)
                                Text("Batch \(progress.currentBatch) of \(progress.totalBatches)")
                                    .font(.subheadline)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }

                        if progress.isCompleted {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Sending completed")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal)

                    // Error List (if any)
                    if !progress.errors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Errors (\(progress.errors.count))")
                                    .font(.headline)
                                Spacer()
                            }

                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 4) {
                                    ForEach(progress.errors.prefix(5), id: \.self) { error in
                                        Text(error)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading)
                                    }

                                    if progress.errors.count > 5 {
                                        Text("... and \(progress.errors.count - 5) more")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading)
                                    }
                                }
                            }
                            .frame(maxHeight: 100)
                        }
                        .padding(.horizontal)
                    }

                    Spacer()

                } else {
                    ProgressView("Preparing to send...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
            .padding()
            .navigationTitle("Sending Messages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if progress?.isCompleted == true {
                        Button("Done") {
                            onCancel()
                        }
                    } else {
                        Button("Cancel") {
                            onCancel()
                        }
                    }
                }
            }
        }
    }
}

struct ProgressInfoRow: View {
    let title: String
    let value: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)

            Text(value)
                .font(.title2)
                .fontWeight(.semibold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    let sampleProgress = AutomatedSendingProgress(
        totalMessages: 100,
        sentCount: 75,
        failedCount: 5,
        currentBatch: 3,
        totalBatches: 5,
        isCompleted: false,
        errors: ["Failed to send to +1234567890", "Failed to send to +0987654321"]
    )

    return AutomatedSendingProgressView(
        progress: sampleProgress,
        onCancel: {}
    )
}
