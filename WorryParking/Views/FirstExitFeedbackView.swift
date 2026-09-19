import SwiftUI
import SwiftData

/// Asked once, right after the first worry leaves through the exit gate:
/// did parking it actually help? The answer stays on this device.
struct FirstExitFeedbackView: View {
    let worry: Worry
    let onDone: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var feeling: ExperienceFeeling?
    @State private var note = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Your first exit")
                            .font(.largeTitle.weight(.bold))
                        Text("You postponed a worry and came back to it on purpose. That's the whole technique.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let after = worry.intensityAfter {
                        LevelChangeView(before: worry.intensityBefore, after: after)
                    }

                    if worry.fearResult == .didNotHappen {
                        Label("What you feared didn't happen. Each exit like this goes into your Exit Log, so you can see how often your worries turn out wrong.", systemImage: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(Theme.readyGreen)
                    }

                    FormSection(title: "While it was parked, how did this worry feel?") {
                        FeelingPicker(moment: .firstExit, selection: $feeling)
                    }

                    if let feeling {
                        FeedbackResponseCard(text: feeling.response(for: .firstExit))
                            .id(feeling)
                    }

                    FeedbackNoteField(note: $note)

                    Button("Done", action: save)
                        .buttonStyle(PrimaryButtonStyle(tint: Theme.readyGreen))
                        .disabled(feeling == nil)
                        .opacity(feeling == nil ? 0.4 : 1)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.asphalt.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now", action: onDone)
                }
            }
        }
        .interactiveDismissDisabled()
    }

    private func save() {
        guard let feeling else { return }
        modelContext.insert(ExperienceFeedback(
            moment: .firstExit,
            feeling: feeling,
            levelBefore: worry.intensityBefore,
            levelAfter: worry.intensityAfter ?? worry.intensityBefore,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        ))
        try? modelContext.save()
        onDone()
    }
}
