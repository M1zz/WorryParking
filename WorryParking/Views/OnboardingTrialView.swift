import SwiftUI
import SwiftData

/// The last onboarding step: park one real worry, notice how loud it is
/// afterwards, and tell us how it felt. The answer stays on this device.
struct OnboardingTrialView: View {
    let onFinish: () -> Void

    @Environment(\.modelContext) private var modelContext
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute

    @Query(filter: #Predicate<Worry> { $0.statusRaw == "parked" })
    private var parked: [Worry]

    private enum Stage {
        case write, tear, parked, reflect
    }

    @State private var stage: Stage = .write
    @State private var text = ""
    @State private var levelBefore = 3
    @State private var levelAfter = 3
    @State private var feeling: ExperienceFeeling?
    @State private var note = ""
    @State private var parkedWorry: Worry?
    @State private var gateOpen = false
    @State private var ticketShown = false
    @State private var askShown = false
    @FocusState private var isEditorFocused: Bool

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var exitDate: Date {
        WorryTime.next(hour: worryHour, minute: worryMinute)
    }

    private var nextSpot: Int {
        Worry.nextFreeSpot(occupied: parked.map(\.spotNumber))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                Group {
                    switch stage {
                    case .write: writeStage
                    case .tear: tearStage
                    case .parked: parkedStage
                    case .reflect: reflectStage
                    }
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)

            buttons
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
                .padding(.top, 8)
        }
    }

    // MARK: - Stages

    private var writeStage: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Try it now")
                    .font(.largeTitle.weight(.bold))
                Text("Write down one worry that's on your mind right now. It will really be parked and come back \(WorryTime.describe(exitDate)).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            FormSection(title: "What's circling in your head?") {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Write it exactly the way it sounds in your head.")
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                    }
                    TextEditor(text: $text)
                        .focused($isEditorFocused)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 110)
                        .accessibilityLabel("Your worry")
                }
                .padding(12)
                .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            FormSection(title: "How loud is it right now?") {
                IntensityPicker(value: $levelBefore, range: 1...5)
            }
        }
    }

    /// Tearing the ticket off is the moment the worry gets parked.
    private var tearStage: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Tear off your ticket")
                    .font(.largeTitle.weight(.bold))
                Text("Swipe along the dotted line. Once it tears off, this worry is parked until \(WorryTime.describe(exitDate)).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            TearOffTicket(
                spot: nextSpot,
                exitAt: exitDate,
                text: trimmedText,
                onTear: park
            )
            .padding(.top, 12)
        }
    }

    @ViewBuilder
    private var parkedStage: some View {
        if let parkedWorry {
            VStack(spacing: 24) {
                GateBarrier(isOpen: gateOpen)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 70)

                if ticketShown {
                    TicketView(worry: parkedWorry, isRevealed: false)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                VStack(spacing: 8) {
                    Text("Parked at P\(parkedWorry.spotNumber)")
                        .font(.title2.weight(.bold))
                    Text("Take one slow breath. There's nothing to do about it right now.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                if askShown {
                    FormSection(title: "Now that it's parked, how loud is it?") {
                        IntensityPicker(value: $levelAfter, range: 0...5)
                    }
                    .transition(.opacity)
                }
            }
            .task {
                try? await Task.sleep(for: .milliseconds(250))
                withAnimation(.spring(duration: 0.8)) { gateOpen = true }
                try? await Task.sleep(for: .milliseconds(350))
                withAnimation(.spring(duration: 0.6)) { ticketShown = true }
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.4)) { askShown = true }
            }
        }
    }

    private var reflectStage: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("How did that feel?")
                .font(.largeTitle.weight(.bold))

            LevelChangeView(before: levelBefore, after: levelAfter)

            FormSection(title: "After parking it, how do you feel?") {
                FeelingPicker(moment: .trial, selection: $feeling)
            }

            if let feeling {
                FeedbackResponseCard(text: feeling.response(for: .trial))
                    .id(feeling)
            }

            FeedbackNoteField(note: $note)
        }
    }

    // MARK: - Buttons

    @ViewBuilder
    private var buttons: some View {
        switch stage {
        case .write:
            VStack(spacing: 12) {
                Button("Next") {
                    isEditorFocused = false
                    withAnimation(.easeInOut(duration: 0.3)) { stage = .tear }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(trimmedText.isEmpty)
                .opacity(trimmedText.isEmpty ? 0.4 : 1)

                Button("Skip for now", action: onFinish)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        case .tear:
            Button {
                withAnimation(.easeInOut(duration: 0.3)) { stage = .write }
            } label: {
                Label("Edit my worry", systemImage: "pencil")
            }
            .buttonStyle(SecondaryButtonStyle())
        case .parked:
            Button("Next") {
                withAnimation(.easeInOut(duration: 0.3)) { stage = .reflect }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!askShown)
            .opacity(askShown ? 1 : 0.4)
        case .reflect:
            Button("Start", action: saveAndFinish)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(feeling == nil)
                .opacity(feeling == nil ? 0.4 : 1)
        }
    }

    // MARK: - Actions

    private func park() {
        guard !trimmedText.isEmpty else { return }
        let worry = Worry(
            text: trimmedText,
            spotNumber: nextSpot,
            intensityBefore: levelBefore,
            exitAt: exitDate
        )
        modelContext.insert(worry)
        try? modelContext.save()

        let ticketID = worry.ticketID
        let spot = worry.spotNumber
        let exit = worry.exitAt
        Task {
            await NotificationManager.scheduleExit(ticketID: ticketID, spot: spot, at: exit)
        }

        isEditorFocused = false
        levelAfter = levelBefore
        parkedWorry = worry
        withAnimation(.easeInOut(duration: 0.3)) { stage = .parked }
    }

    private func saveAndFinish() {
        guard let feeling else { return }
        modelContext.insert(ExperienceFeedback(
            moment: .trial,
            feeling: feeling,
            levelBefore: levelBefore,
            levelAfter: levelAfter,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        try? modelContext.save()
        onFinish()
    }
}
