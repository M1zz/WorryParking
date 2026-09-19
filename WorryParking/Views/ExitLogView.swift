import SwiftUI
import SwiftData
import Charts

struct ExitLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store

    @Query(filter: #Predicate<Worry> { $0.statusRaw == "reviewed" })
    private var reviewedWorries: [Worry]

    @Query(sort: \ExperienceFeedback.createdAt)
    private var feedback: [ExperienceFeedback]

    @State private var showingPaywall = false

    private var history: [Worry] {
        reviewedWorries.sorted { ($0.reviewedAt ?? .distantPast) > ($1.reviewedAt ?? .distantPast) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if history.isEmpty && feedback.isEmpty {
                    ContentUnavailableView(
                        "No exits yet",
                        systemImage: "car.side",
                        description: Text("Worries you review at the exit gate land here. Over time you'll see how many of them actually happened.")
                    )
                } else {
                    List {
                        if !history.isEmpty {
                            Section {
                                InsightsCard(
                                    summary: InsightsSummary(worries: history),
                                    isUnlocked: store.isPro
                                ) { showingPaywall = true }
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                            }
                        }

                        if !feedback.isEmpty {
                            Section("Your experience") {
                                ForEach(feedback) { entry in
                                    ExperienceRow(entry: entry)
                                        .listRowBackground(Theme.asphaltLight)
                                }
                            }
                        }

                        if !history.isEmpty {
                            Section("History") {
                                ForEach(history) { worry in
                                    ExitLogRow(worry: worry)
                                        .listRowBackground(Theme.asphaltLight)
                                }
                                .onDelete(perform: delete)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .background(Theme.asphalt.ignoresSafeArea())
            .navigationTitle("Exit Log")
            .toolbarBackground(Theme.asphalt, for: .navigationBar)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let items = history
        for index in offsets {
            modelContext.delete(items[index])
        }
        try? modelContext.save()
    }
}

struct InsightsCard: View {
    let summary: InsightsSummary
    let isUnlocked: Bool
    let onUnlock: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                StatTile(value: "\(summary.total)", label: String(localized: "Exited"))
                StatTile(
                    value: summary.didNotHappenRate.map { $0.formatted(.percent.precision(.fractionLength(0))) } ?? "–",
                    label: String(localized: "Didn't happen")
                )
                StatTile(
                    value: summary.averageDrop.map { $0.formatted(.number.precision(.fractionLength(1))) } ?? "–",
                    label: String(localized: "Avg. level drop")
                )
            }

            Chart(summary.resultCounts) { item in
                BarMark(
                    x: .value("Count", item.count),
                    y: .value("Result", item.result.title)
                )
                .foregroundStyle(item.result.color)
                .annotation(position: .trailing) {
                    Text("\(item.count)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 150)

            Text(summary.headline)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .blur(radius: isUnlocked ? 0 : 8)
        .accessibilityHidden(!isUnlocked)
        .overlay {
            if !isUnlocked {
                Button(action: onUnlock) {
                    VStack(spacing: 8) {
                        Image(systemName: "lock.fill")
                            .font(.title2)
                        Text("See how many of your worries actually happened")
                            .font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.center)
                        Text("Unlock Insights with Pro")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Theme.lineYellow, in: Capsule())
                    }
                    .padding(20)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct ExitLogRow: View {
    let worry: Worry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("P\(worry.spotNumber) · #\(worry.ticketNumber)")
                    .font(.caption.monospaced())
                    .foregroundStyle(Theme.lineYellow)
                Spacer()
                if let reviewedAt = worry.reviewedAt {
                    Text(reviewedAt, format: .dateTime.month(.abbreviated).day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(worry.text)
                .font(.body)
                .lineLimit(3)
                .privacySensitive()

            HStack(spacing: 6) {
                if let result = worry.fearResult {
                    Tag(text: result.title, color: result.color)
                }
                if let after = worry.intensityAfter {
                    Tag(text: String(localized: "Level \(worry.intensityBefore) → \(after)"), color: .gray)
                }
                if let outcome = worry.outcome {
                    Tag(text: outcome.title, color: Theme.signBlue)
                }
            }

            if let step = worry.actionStep {
                Label(step, systemImage: "arrow.turn.down.right")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

/// What the user said about postponing, played back to them.
struct ExperienceRow: View {
    let entry: ExperienceFeedback

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.moment.title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(entry.createdAt, format: .dateTime.month(.abbreviated).day())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 6) {
                Tag(text: entry.feeling.title(for: entry.moment), color: entry.feeling.color)
                Tag(text: String(localized: "Level \(entry.levelBefore) → \(entry.levelAfter)"), color: .gray)
            }
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .privacySensitive()
            }
        }
        .padding(.vertical, 6)
    }
}
