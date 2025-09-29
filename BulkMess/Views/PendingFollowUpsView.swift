import SwiftUI

struct PendingFollowUpsView: View {
    @EnvironmentObject var followUpService: FollowUpService
    @State private var items: [FollowUpService.ScheduledFollowUp] = []
    @State private var sendingID: String? = nil
    @State private var sendingAll: Bool = false

    struct CampaignGroup: Identifiable {
        let id: String
        let name: String
        let items: [FollowUpService.ScheduledFollowUp]
        let nextDate: Date?
    }

    private var groups: [CampaignGroup] {
        var dict: [String: [FollowUpService.ScheduledFollowUp]] = [:]
        for it in items {
            let key = it.campaign?.objectID.uriRepresentation().absoluteString ?? "unknown"
            dict[key, default: []].append(it)
        }
        let result: [CampaignGroup] = dict.map { key, arr in
            let name = arr.first?.campaign?.name ?? "Unknown Campaign"
            let next = arr.compactMap { $0.scheduledDate }.min()
            return CampaignGroup(id: key, name: name, items: arr.sorted { ($0.scheduledDate ?? .distantFuture) < ($1.scheduledDate ?? .distantFuture) }, nextDate: next)
        }
        return result.sorted { (a, b) in
            switch (a.nextDate, b.nextDate) {
            case let (ad?, bd?): return ad < bd
            case (_?, nil): return true
            case (nil, _?): return false
            default: return a.name < b.name
            }
        }
    }

    private var dueItems: [FollowUpService.ScheduledFollowUp] {
        let now = Date()
        return items.filter { ($0.scheduledDate ?? now) <= now }
            .sorted { ($0.scheduledDate ?? .distantPast) < ($1.scheduledDate ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Pending Follow-ups",
                        systemImage: "checkmark.seal",
                        description: Text("Scheduled follow-ups will appear here before they send.")
                    )
                } else {
                    List {
                        ForEach(groups) { group in
                            Section {
                                ForEach(group.items) { item in
                                    row(item)
                                }
                            } header: {
                                HStack {
                                    Text(group.name)
                                    Spacer()
                                    if let next = group.nextDate {
                                        Text("Next: \(next.formatted(date: .abbreviated, time: .shortened))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { reload() }
                }
            }
            .navigationTitle("Follow-ups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !dueItems.isEmpty {
                        Button {
                            sendAllDue()
                        } label: {
                            if sendingAll { ProgressView() } else { Text("Send All Due (\(dueItems.count))") }
                        }
                        .disabled(sendingAll)
                    }
                }
            }
            .onAppear(perform: reload)
        }
    }

    private func row(_ item: FollowUpService.ScheduledFollowUp) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle().fill(Color.blue.opacity(0.15)).frame(width: 36, height: 36)
                .overlay(Image(systemName: "clock").foregroundColor(.blue))

            VStack(alignment: .leading, spacing: 6) {
                Text(contactName(item))
                    .font(.headline)
                if let step = item.followUpMessage?.stepNumber {
                    Text("Step \(step)").font(.caption).foregroundColor(.secondary)
                }
                if let date = item.scheduledDate {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 8) {
                Button {
                    sendingID = item.identifier
                    followUpService.executeScheduledFollowUp(item) { _ in
                        reload()
                        sendingID = nil
                    }
                } label: {
                    if sendingID == item.identifier {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    followUpService.cancelScheduledFollowUp(identifier: item.identifier) {
                        reload()
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
    }

    private func contactName(_ item: FollowUpService.ScheduledFollowUp) -> String {
        if let c = item.contact {
            let first = c.firstName ?? ""; let last = c.lastName ?? ""
            if !first.isEmpty || !last.isEmpty { return "\(first) \(last)".trimmingCharacters(in: .whitespaces) }
            return c.phoneNumber ?? "Unknown"
        }
        return "Unknown"
    }

    private func reload() {
        followUpService.getScheduledFollowUps { scheduledFollowUps in
            DispatchQueue.main.async {
                self.items = scheduledFollowUps
            }
        }
    }

    private func sendAllDue() {
        let queue = dueItems
        guard !queue.isEmpty else { return }
        sendingAll = true
        func next(_ idx: Int) {
            if idx >= queue.count {
                sendingAll = false
                reload()
                return
            }
            let item = queue[idx]
            followUpService.executeScheduledFollowUp(item) { _ in
                next(idx + 1)
            }
        }
        next(0)
    }
}

#Preview {
    PendingFollowUpsView().environmentObject(FollowUpService(templateManager: MessageTemplateManager(), messagingService: MessagingService()))
}
