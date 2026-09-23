import SwiftUI
import SwiftData

/// Tapping a parked car shows its ticket — but the worry stays hidden.
struct ParkedTicketSheet: View {
    let worry: Worry

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var confirmingEarlyExit = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    TicketView(worry: worry, isRevealed: false)

                    VStack(spacing: 8) {
                        Text("Parked until \(WorryTime.describe(worry.exitAt))")
                            .font(.headline)
                        Text("If it drives back into your head, notice it and tell yourself: it has a spot. You'll deal with it at Worry Time.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        confirmingEarlyExit = true
                    } label: {
                        Label("Retrieve early", systemImage: "arrow.up.right")
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
                .padding(24)
            }
            .background(Theme.asphalt.ignoresSafeArea())
            .navigationTitle("P\(worry.spotNumber)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Retrieve this worry early?",
                isPresented: $confirmingEarlyExit,
                titleVisibility: .visible
            ) {
                Button("Send it to the exit gate now") { retrieveEarly() }
                Button("Keep it parked", role: .cancel) {}
            } message: {
                Text("Postponing works best when you wait. Most worries feel smaller by Worry Time.")
            }
        }
        .presentationDetents([.large])
    }

    private func retrieveEarly() {
        // Slightly in the past so the lot's timeline treats it as ready immediately.
        worry.exitAt = Date.now.addingTimeInterval(-60)
        NotificationManager.cancel(ticketID: worry.ticketID)
        try? modelContext.save()
        dismiss()
    }
}
