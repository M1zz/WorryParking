import SwiftUI

struct FormSection<Content: View>: View {
    let title: LocalizedStringKey
    var footer: LocalizedStringKey? = nil
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            content
            if let footer {
                Text(footer)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct IntensityPicker: View {
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                ForEach(Array(range), id: \.self) { level in
                    Button {
                        value = level
                    } label: {
                        Text("\(level)")
                            .font(.headline.monospacedDigit())
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(fill(for: level), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .foregroundStyle(level == value ? Theme.ink : Color.white)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(level), \(Intensity.label(level))")
                    .accessibilityAddTraits(level == value ? .isSelected : [])
                }
            }
            Text(Intensity.label(value))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
    }

    private func fill(for level: Int) -> Color {
        if level == value { return Theme.lineYellow }
        if level < value { return Theme.lineYellow.opacity(0.28) }
        return Theme.asphaltLight
    }
}

struct IntensityDots: View {
    let level: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { index in
                Circle()
                    .fill(index <= level ? Theme.ink : Theme.ink.opacity(0.15))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Level \(level) of 5, \(Intensity.label(level))")
    }
}

struct SelectableRow: View {
    let title: String
    let detail: String
    let isSelected: Bool
    var isLocked = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: isLocked ? "lock.fill" : (isSelected ? "checkmark.circle.fill" : "circle"))
                    .font(.title3)
                    .foregroundStyle(isSelected ? Theme.lineYellow : Color.secondary)
            }
            .padding(14)
            .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.lineYellow : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct ChoiceChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, 8)
                .background(
                    isSelected ? Theme.lineYellow : Theme.asphaltLight,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
                .foregroundStyle(isSelected ? Theme.ink : Color.white)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct Tag: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.25), in: Capsule())
    }
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .fontDesign(.rounded)
                .foregroundStyle(Theme.lineYellow)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
