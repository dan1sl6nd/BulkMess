import SwiftUI

struct FollowUpSequencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var followUpService: FollowUpService
    @EnvironmentObject var templateManager: MessageTemplateManager

    @State private var showingAdd = false
    @State private var selectedSequence: FollowUpSequence?
    @State private var sequences: [FollowUpSequence] = []

    var body: some View {
        NavigationStack {
            Group {
                if sequences.isEmpty {
                    ContentUnavailableView(
                        "No Follow-up Sequences",
                        systemImage: "arrow.clockwise",
                        description: Text("Create sequences of delayed follow-up messages using your templates.")
                    )
                } else {
                    List {
                        ForEach(sequences, id: \.objectID) { seq in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(seq.name ?? "Untitled Sequence")
                                        .font(.headline)
                                    Spacer()
                                    StatusPill(
                                        text: seq.isActive ? "Active" : "Inactive",
                                        background: seq.isActive ? .green : .gray,
                                        foreground: seq.isActive ? .green : .gray
                                    )
                                }
                                if let msgs = (seq.followUpMessages?.allObjects as? [FollowUpMessage])?.sorted(by: { $0.stepNumber < $1.stepNumber }), !msgs.isEmpty {
                                    Text("\(msgs.count) step\(msgs.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { selectedSequence = seq }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { idx in
                                let seq = sequences[idx]
                                followUpService.deleteFollowUpSequence(seq)
                            }
                            reload()
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(AppTheme.background)
                }
            }
            .navigationTitle("Follow-ups")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAdd = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear(perform: reload)
            .sheet(isPresented: $showingAdd, onDismiss: reload) {
                FollowUpSequenceEditorView(sequence: nil)
            }
            .sheet(item: $selectedSequence, onDismiss: reload) { seq in
                FollowUpSequenceEditorView(sequence: seq)
            }
        }
    }

    private func reload() {
        sequences = followUpService.getFollowUpSequences()
    }
}

struct FollowUpSequenceEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var followUpService: FollowUpService
    @EnvironmentObject var templateManager: MessageTemplateManager

    let sequence: FollowUpSequence?

    @State private var name: String = ""
    @State private var isActive: Bool = true
    @State private var steps: [FollowUpMessageData] = []

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Sequence Name", text: $name)
                    Toggle("Active", isOn: $isActive)
                }

                Section("Steps") {
                    if steps.isEmpty {
                        Text("No steps yet. Add a step to start.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(steps.indices, id: \.self) { idx in
                            FollowUpStepEditor(index: idx + 1, data: $steps[idx], templates: templateManager.templates)
                        }
                        .onDelete { indexSet in
                            steps.remove(atOffsets: indexSet)
                        }
                        .onMove { src, dst in
                            steps.move(fromOffsets: src, toOffset: dst)
                        }
                    }

                    Button {
                        if let firstTemplate = templateManager.templates.first {
                            steps.append(FollowUpMessageData(template: firstTemplate, delayDays: 1, delayHours: 0))
                        }
                    } label: {
                        Label("Add Step", systemImage: "plus.circle")
                    }
                    .disabled(templateManager.templates.isEmpty)
                }
            }
            .navigationTitle(sequence == nil ? "New Sequence" : "Edit Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                    .disabled(!isValid)
                }
            }
            .onAppear(perform: load)
        }
    }

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    private func load() {
        if let seq = sequence {
            name = seq.name ?? ""
            isActive = seq.isActive
            if let msgs = (seq.followUpMessages?.allObjects as? [FollowUpMessage])?.sorted(by: { $0.stepNumber < $1.stepNumber }) {
                steps = msgs.map { FollowUpMessageData(template: $0.template!, delayDays: Int($0.delayDays), delayHours: Int($0.delayHours)) }
            }
        }
    }

    private func save() {
        if let seq = sequence {
            // Update
            followUpService.updateFollowUpSequence(seq, name: name, followUpMessages: steps)
            seq.isActive = isActive
        } else {
            let new = followUpService.createFollowUpSequence(name: name, followUpMessages: steps)
            new.isActive = isActive
        }
        dismiss()
    }
}

struct FollowUpStepEditor: View {
    let index: Int
    @Binding var data: FollowUpMessageData
    let templates: [MessageTemplate]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(index)").font(.headline)
                Spacer()
            }
            Picker("Template", selection: templateBinding) {
                ForEach(templates, id: \.objectID) { t in
                    Text(t.name ?? "Untitled").tag(t as MessageTemplate?)
                }
            }
            HStack {
                Stepper(value: $data.delayDays, in: 0...365) { Text("Days: \(data.delayDays)") }
                Stepper(value: $data.delayHours, in: 0...23) { Text("Hours: \(data.delayHours)") }
            }
        }
    }

    private var templateBinding: Binding<MessageTemplate?> {
        Binding<MessageTemplate?>(
            get: { data.template },
            set: { newValue in
                if let t = newValue { data = FollowUpMessageData(template: t, delayDays: data.delayDays, delayHours: data.delayHours) }
            }
        )
    }
}

