import SwiftUI
import SwiftData

/// Worry Time review: reveal the worry, reality-check it, then decide.
struct ExitGateView: View {
    let worry: Worry

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute
    @AppStorage(SettingsKey.askedFirstExitFeedback) private var askedFirstExitFeedback = false

    @State private var session = Date.now...Date.now.addingTimeInterval(TimeInterval(AppConfig.worrySessionMinutes * 60))
    @State private var fearResult: FearResult?
    @State private var intensityNow = 3
    @State private var decision: ExitDecision?
    @State private var nextStep = ""
    @State private var finished = false
    @State private var askingFeedback = false

    enum ExitDecision: CaseIterable, Identifiable {
        case letGo
        case plan
        case repark

        var id: Self { self }

        var title: String {
            switch self {
            case .letGo: String(localized: "Let it go")
            case .plan: String(localized: "Make a plan")
            case .repark: String(localized: "Park it again")
            }
        }

        var detail: String {
            switch self {
            case .letGo: String(localized: "It's out of the lot. Drive away.")
            case .plan: String(localized: "Turn it into one small next step.")
            case .repark: String(localized: "Not ready yet. Bring it back at the next Worry Time.")
            }
        }
    }

    private var trimmedStep: String {
        nextStep.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canFinish: Bool {
        guard let decision else { return false }
        switch decision {
        case .repark: return true
        case .letGo: return fearResult != nil
        case .plan: return fearResult != nil && !trimmedStep.isEmpty
        }
    }

    private var finishTitle: String {
        decision == .repark ? String(localized: "Park it again") : String(localized: "Drive out")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    sessionBanner

                    TicketView(worry: worry, isRevealed: true)

                    FormSection(title: "Did what you feared actually happen?") {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(FearResult.allCases) { result in
                                ChoiceChip(
                                    title: result.title,
                                    systemImage: result.symbol,
                                    isSelected: fearResult == result
                                ) { fearResult = result }
                            }
                        }
                    }

                    FormSection(
                        title: "How loud is it now?",
                        footer: "It was \(worry.intensityBefore) when you parked it."
                    ) {
                        IntensityPicker(value: $intensityNow, range: 0...5)
                    }

                    FormSection(title: "What do you want to do with it?") {
                        VStack(spacing: 10) {
                            ForEach(ExitDecision.allCases) { option in
                                SelectableRow(
                                    title: option.title,
                                    detail: option.detail,
                                    isSelected: decision == option
                                ) { decision = option }
                            }
                            if decision == .plan {
                                TextField("One small next step", text: $nextStep, axis: .vertical)
                                    .lineLimit(2...4)
                                    .padding(14)
                                    .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                    }

                    Button(action: finish) {
                        Label(finishTitle, systemImage: "arrow.up.right")
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.readyGreen))
                    .disabled(!canFinish)
                    .opacity(canFinish ? 1 : 0.4)
                }
                .padding(20)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.asphalt.ignoresSafeArea())
            .navigationTitle("Exit Gate · P\(worry.spotNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Later") { dismiss() }
                }
            }
            .onAppear { intensityNow = worry.intensityBefore }
            .sensoryFeedback(.success, trigger: finished)
            .sheet(isPresented: $askingFeedback) {
                FirstExitFeedbackView(worry: worry) {
                    askingFeedback = false
                    dismiss()
                }
            }
        }
    }

    private var sessionBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(Theme.lineYellow)
            VStack(alignment: .leading, spacing: 2) {
                Text("Worry Time")
                    .font(.headline)
                Text("Give it your full attention. It's the only thing to do right now.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(timerInterval: session, countsDown: true)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(Theme.lineYellow)
        }
        .padding(14)
        .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func finish() {
        guard canFinish, let decision else { return }
        let ticketID = worry.ticketID
        let spot = worry.spotNumber

        switch decision {
        case .repark:
            let next = WorryTime.next(hour: worryHour, minute: worryMinute, minimumLead: 2 * 60 * 60)
            worry.exitAt = next
            worry.reparkCount += 1
            Task {
                await NotificationManager.scheduleExit(ticketID: ticketID, spot: spot, at: next)
            }
        case .letGo, .plan:
            worry.fearResult = fearResult
            worry.intensityAfter = intensityNow
            worry.outcome = decision == .plan ? .plan : .letGo
            worry.actionStep = decision == .plan ? trimmedStep : nil
            worry.reviewedAt = .now
            worry.status = .reviewed
            NotificationManager.cancel(ticketID: ticketID)
        }

        try? modelContext.save()
        finished = true

        if decision != .repark && !askedFirstExitFeedback {
            askedFirstExitFeedback = true
            askingFeedback = true
        } else {
            dismiss()
        }
    }
}

#if DEBUG
extension ExitGateView {
    /// Screenshot mode: a review already in progress.
    init(worry: Worry, fearResult: FearResult) {
        self.worry = worry
        _fearResult = State(initialValue: fearResult)
    }
}
#endif
