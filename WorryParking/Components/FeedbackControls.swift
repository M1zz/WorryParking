import SwiftUI

/// "How did it feel?" choices, worded for the moment being asked about.
struct FeelingPicker: View {
    let moment: FeedbackMoment
    @Binding var selection: ExperienceFeeling?

    var body: some View {
        VStack(spacing: 10) {
            ForEach(ExperienceFeeling.allCases) { feeling in
                ChoiceChip(
                    title: feeling.title(for: moment),
                    systemImage: feeling.symbol,
                    isSelected: selection == feeling
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) { selection = feeling }
                }
            }
        }
    }
}

/// A reply to the user's answer, styled like a note on ticket paper.
struct FeedbackResponseCard: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(Theme.ink)
            .fixedSize(horizontal: false, vertical: true)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.ticketPaper, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

/// Before → after intensity, big enough to notice the change.
struct LevelChangeView: View {
    let before: Int
    let after: Int

    var body: some View {
        HStack(spacing: 20) {
            level(before, label: "Before")
            Image(systemName: "arrow.right")
                .font(.title2.weight(.bold))
                .foregroundStyle(.secondary)
            level(after, label: "Now")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Level \(before) → \(after)"))
    }

    private func level(_ value: Int, label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 44, weight: .black, design: .rounded))
                .foregroundStyle(Theme.lineYellow)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(Intensity.label(value))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: 90)
    }
}

struct FeedbackNoteField: View {
    @Binding var note: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Anything else? (optional)", text: $note, axis: .vertical)
                .lineLimit(2...4)
                .padding(14)
                .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Label("Your answers stay on this iPhone. You can look back at them in your Exit Log.", systemImage: "lock.fill")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
