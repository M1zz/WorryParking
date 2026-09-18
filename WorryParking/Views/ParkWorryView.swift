import SwiftUI
import SwiftData

struct ParkWorryView: View {
    let spot: Int

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute

    @State private var text = ""
    @State private var intensity = 3
    @State private var exitChoice: ExitChoice = .nextWorryTime
    @State private var customExit = Date.now.addingTimeInterval(3 * 60 * 60)
    @State private var issued: Worry?
    @State private var showingPaywall = false
    @FocusState private var isEditorFocused: Bool

    enum ExitChoice: Hashable {
        case nextWorryTime
        case followingWorryTime
        case custom
    }

    private var nextWorryTime: Date {
        WorryTime.next(hour: worryHour, minute: worryMinute)
    }

    private var followingWorryTime: Date {
        WorryTime.sameTimeNextDay(after: nextWorryTime)
    }

    private var exitDate: Date {
        switch exitChoice {
        case .nextWorryTime: nextWorryTime
        case .followingWorryTime: followingWorryTime
        case .custom: customExit
        }
    }

    private var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canPark: Bool {
        !trimmedText.isEmpty && exitDate > .now
    }

    private var title: String {
        issued == nil ? String(localized: "Park at P\(spot)") : ""
    }

    var body: some View {
        NavigationStack {
            Group {
                if let issued {
                    TicketIssuedView(worry: issued) { dismiss() }
                        .transition(.opacity)
                } else {
                    form
                }
            }
            .background(Theme.asphalt.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if issued == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
        .interactiveDismissDisabled(!trimmedText.isEmpty && issued == nil)
        .sensoryFeedback(.success, trigger: issued != nil)
    }

    private var form: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
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
                            .frame(minHeight: 130)
                            .accessibilityLabel("Your worry")
                    }
                    .padding(12)
                    .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                FormSection(title: "How loud is it right now?") {
                    IntensityPicker(value: $intensity, range: 1...5)
                }

                FormSection(
                    title: "When should it come back?",
                    footer: "Your daily Worry Time is \(WorryTime.timeString(hour: worryHour, minute: worryMinute)). You can change it in Settings."
                ) {
                    VStack(spacing: 10) {
                        SelectableRow(
                            title: String(localized: "Next Worry Time"),
                            detail: WorryTime.describe(nextWorryTime).capitalizedFirst,
                            isSelected: exitChoice == .nextWorryTime
                        ) { exitChoice = .nextWorryTime }

                        SelectableRow(
                            title: String(localized: "The Worry Time after"),
                            detail: WorryTime.describe(followingWorryTime).capitalizedFirst,
                            isSelected: exitChoice == .followingWorryTime
                        ) { exitChoice = .followingWorryTime }

                        SelectableRow(
                            title: String(localized: "Custom time"),
                            detail: store.isPro ? WorryTime.describe(customExit).capitalizedFirst : "Worry Parking Pro",
                            isSelected: exitChoice == .custom,
                            isLocked: !store.isPro
                        ) {
                            if store.isPro {
                                exitChoice = .custom
                            } else {
                                showingPaywall = true
                            }
                        }

                        if exitChoice == .custom {
                            DatePicker(
                                "Exit time",
                                selection: $customExit,
                                in: Date.now.addingTimeInterval(5 * 60)...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .padding(.horizontal, 4)
                        }
                    }
                }

                Button(action: park) {
                    Label("Park it", systemImage: "parkingsign")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canPark)
                .opacity(canPark ? 1 : 0.4)
            }
            .padding(20)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear { isEditorFocused = true }
    }

    private func park() {
        guard canPark else { return }
        let worry = Worry(
            text: trimmedText,
            spotNumber: spot,
            intensityBefore: intensity,
            exitAt: exitDate
        )
        modelContext.insert(worry)
        try? modelContext.save()

        let ticketID = worry.ticketID
        let spotNumber = worry.spotNumber
        let exit = worry.exitAt
        Task {
            await NotificationManager.scheduleExit(ticketID: ticketID, spot: spotNumber, at: exit)
        }

        isEditorFocused = false
        withAnimation(.easeInOut(duration: 0.3)) {
            issued = worry
        }
    }
}

/// Shown right after parking: the barrier lifts and the ticket slides in, text hidden.
struct TicketIssuedView: View {
    let worry: Worry
    let onDone: () -> Void

    @State private var gateOpen = false
    @State private var ticketShown = false

    var body: some View {
        VStack(spacing: 28) {
            GateBarrier(isOpen: gateOpen)
                .frame(maxWidth: .infinity, alignment: .leading)

            if ticketShown {
                TicketView(worry: worry, isRevealed: false)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack(spacing: 8) {
                Text("Parked at P\(worry.spotNumber)")
                    .font(.title2.weight(.bold))
                Text("You don't need to carry this right now. We'll bring it back \(WorryTime.describe(worry.exitAt)).")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: 0)

            Button(action: onDone) {
                Text("Done")
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
        .task {
            try? await Task.sleep(for: .milliseconds(250))
            withAnimation(.spring(duration: 0.8)) { gateOpen = true }
            try? await Task.sleep(for: .milliseconds(350))
            withAnimation(.spring(duration: 0.6)) { ticketShown = true }
        }
    }
}
