import SwiftUI

/// A ticket still attached to its stub. Dragging a finger along the dotted
/// line tears it off, and tearing it off is what parks the worry.
struct TearOffTicket: View {
    let spot: Int
    let exitAt: Date
    /// The worry itself, shown on the ticket while it's still in your hand.
    var text: String?
    var isEnabled = true
    let onTear: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How far along the dotted line the tear has run, 0...1.
    @State private var progress: CGFloat = 0
    @State private var isTorn = false
    /// A drag only tears if it starts near the left end of the line.
    @State private var dragIsTearing: Bool?
    @State private var nudge = false

    private let tearThreshold: CGFloat = 0.85
    private let cornerRadius: CGFloat = 16
    private let notchRadius: CGFloat = 11

    var body: some View {
        VStack(spacing: 0) {
            ticketBody
            // Drawn over the ticket so the scissors can sit right on the seam.
            stub
                .zIndex(1)
        }
        .foregroundStyle(Theme.ink)
        .opacity(isEnabled ? 1 : 0.45)
        .allowsHitTesting(isEnabled && !isTorn)
        .sensoryFeedback(.selection, trigger: tick) { old, new in new > old }
        .sensoryFeedback(.impact(weight: .medium), trigger: isTorn) { _, new in new }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Tear off the ticket to park"))
        .accessibilityHint(Text("Swipe along the dotted line to park"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { tear() }
        .onAppear { nudge = true }
    }

    private var tick: Int { Int(progress * 10) }

    private var ticketBody: some View {
        VStack(alignment: .leading, spacing: 14) {
            ticketHeader
            if let text {
                Text(text)
                    .font(.body)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .privacySensitive()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Theme.ticketPaper,
            in: UnevenRoundedRectangle(topLeadingRadius: cornerRadius, topTrailingRadius: cornerRadius)
        )
        .scaleEffect(isTorn && !reduceMotion ? 1.03 : 1)
    }

    private var ticketHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            ParkingSign(size: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("WORRY PARKING")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                HStack(spacing: 6) {
                    Text("EXIT")
                        .font(.caption2.weight(.bold))
                        .opacity(0.6)
                    Text(exitAt, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.subheadline.monospacedDigit().weight(.semibold))
                }
            }
            Spacer(minLength: 0)
            Text("P\(spot)")
                .font(.system(size: 30, weight: .black, design: .rounded))
        }
    }

    /// Half-circle bites at both ends of the tear line, like `TicketShape`.
    private var notches: some View {
        HStack {
            Circle().frame(width: notchRadius * 2).offset(x: -notchRadius)
            Spacer()
            Circle().frame(width: notchRadius * 2).offset(x: notchRadius)
        }
        .frame(height: notchRadius * 2)
        .offset(y: -notchRadius)
        .foregroundStyle(Theme.asphalt)
        .accessibilityHidden(true)
    }

    private var stub: some View {
        Label("Swipe along the dotted line to park", systemImage: "hand.draw")
            .font(.footnote.weight(.semibold))
            .opacity(0.6)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 24)
            .background(
                Theme.ticketPaper,
                in: UnevenRoundedRectangle(bottomLeadingRadius: cornerRadius, bottomTrailingRadius: cornerRadius)
            )
            .overlay(alignment: .top) { notches }
            .overlay(alignment: .top) { tearLine }
            // The stub hangs from the part that isn't torn yet, then drops away.
            .rotationEffect(.degrees(isTorn ? 18 : progress * 5), anchor: .topTrailing)
            .offset(y: isTorn ? 160 : 0)
            .opacity(isTorn ? 0 : 1)
    }

    private var tearLine: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let midY = proxy.size.height / 2
            ZStack(alignment: .leading) {
                DashedLine()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                    .foregroundStyle(Theme.ink.opacity(0.35))
                    .frame(height: 1)
                    .padding(.horizontal, notchRadius + 4)

                // The torn stretch opens into a gap the asphalt shows through.
                Rectangle()
                    .fill(Theme.asphalt)
                    .frame(width: width * progress, height: 2)

                Image(systemName: "scissors")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 30, height: 30)
                    .background(Theme.lineYellow, in: Circle())
                    .shadow(color: .black.opacity(0.25), radius: 3, y: 1)
                    .position(
                        x: max(20, width * progress) + (progress == 0 && nudge && !reduceMotion && isEnabled ? 14 : 0),
                        y: midY
                    )
                    .animation(
                        progress == 0 && !reduceMotion
                            ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                            : .interactiveSpring,
                        value: nudge
                    )
                    .opacity(isTorn ? 0 : 1)
            }
            .frame(width: width, height: proxy.size.height)
            .contentShape(Rectangle())
            .gesture(tearGesture(width: width))
        }
        .frame(height: 48)
        .offset(y: -24)
    }

    private func tearGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                if dragIsTearing == nil {
                    dragIsTearing = value.startLocation.x < width * 0.35
                }
                guard dragIsTearing == true, width > 0 else { return }
                // A tear only runs forward; backing up doesn't mend the paper.
                let reached = min(max(value.location.x / width, 0), 1)
                if reached > progress { progress = reached }
                if progress >= 0.98 { tear() }
            }
            .onEnded { _ in
                dragIsTearing = nil
                guard !isTorn else { return }
                if progress >= tearThreshold {
                    tear()
                } else {
                    withAnimation(.spring(duration: 0.35)) { progress = 0 }
                }
            }
    }

    private func tear() {
        guard isEnabled, !isTorn else { return }
        withAnimation(.easeIn(duration: 0.35)) {
            progress = 1
            isTorn = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 50 : 350))
            onTear()
        }
    }
}
