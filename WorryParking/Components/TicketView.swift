import SwiftUI

/// A paper parking ticket. The worry text is blurred until exit time.
struct TicketView: View {
    let spot: Int
    let ticketNumber: String
    let parkedAt: Date
    let exitAt: Date
    let text: String
    let intensity: Int
    let isRevealed: Bool

    private let stubHeight: CGFloat = 72

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center, spacing: 12) {
                    ParkingSign(size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WORRY PARKING")
                            .font(.caption.weight(.heavy))
                            .tracking(2)
                        Text("Ticket #\(ticketNumber)")
                            .font(.caption.monospaced())
                            .opacity(0.6)
                    }
                    Spacer()
                    Text("P\(spot)")
                        .font(.system(size: 34, weight: .black, design: .rounded))
                }

                worryText

                HStack(spacing: 8) {
                    Text("LEVEL")
                        .font(.caption2.weight(.bold))
                        .opacity(0.6)
                    IntensityDots(level: intensity)
                }
            }
            .padding(20)

            DashedLine()
                .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 5]))
                .foregroundStyle(Theme.ink.opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal, 20)

            HStack {
                stamp(label: "IN", date: parkedAt, alignment: .leading)
                Spacer()
                stamp(label: "EXIT", date: exitAt, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .frame(height: stubHeight)
        }
        .foregroundStyle(Theme.ink)
        .background(Theme.ticketPaper, in: TicketShape(stubHeight: stubHeight))
        .shadow(color: .black.opacity(0.35), radius: 12, y: 6)
    }

    @ViewBuilder
    private var worryText: some View {
        if isRevealed {
            Text(text)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .privacySensitive()
        } else {
            Text(text)
                .font(.body)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .blur(radius: 7)
                .accessibilityHidden(true)
                .overlay {
                    Label("Parked. Not your job right now.", systemImage: "lock.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.ticketPaper)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Theme.ink, in: Capsule())
                }
                .frame(minHeight: 56)
        }
    }

    private func stamp(label: String, date: Date, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(label)
                .font(.caption2.weight(.bold))
                .opacity(0.6)
            Text(date, format: .dateTime.month(.abbreviated).day().hour().minute())
                .font(.subheadline.monospacedDigit().weight(.semibold))
        }
        .accessibilityElement(children: .combine)
    }
}

extension TicketView {
    init(worry: Worry, isRevealed: Bool) {
        self.init(
            spot: worry.spotNumber,
            ticketNumber: worry.ticketNumber,
            parkedAt: worry.parkedAt,
            exitAt: worry.exitAt,
            text: worry.text,
            intensity: worry.intensityBefore,
            isRevealed: isRevealed
        )
    }
}

/// Rounded rectangle with two semicircle notches where the stub tears off.
struct TicketShape: Shape {
    var stubHeight: CGFloat
    var cornerRadius: CGFloat = 16
    var notchRadius: CGFloat = 11

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let notchY = rect.maxY - stubHeight
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.minY + r), radius: r,
                    startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        path.addLine(to: CGPoint(x: rect.maxX, y: notchY - notchRadius))
        path.addArc(center: CGPoint(x: rect.maxX, y: notchY), radius: notchRadius,
                    startAngle: .degrees(-90), endAngle: .degrees(90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r), radius: r,
                    startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r), radius: r,
                    startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        path.addLine(to: CGPoint(x: rect.minX, y: notchY + notchRadius))
        path.addArc(center: CGPoint(x: rect.minX, y: notchY), radius: notchRadius,
                    startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(center: CGPoint(x: rect.minX + r, y: rect.minY + r), radius: r,
                    startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        path.closeSubpath()
        return path
    }
}

struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// Parking bay markings: two side lines and a back line, open at the front.
struct SpotLines: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

/// Striped boom barrier that lifts when a ticket is issued.
struct GateBarrier: View {
    let isOpen: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.7))
                .frame(width: 18, height: 72)
            HStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    Rectangle().fill(index.isMultiple(of: 2) ? Theme.lineYellow : Theme.ink)
                }
            }
            .frame(width: 210, height: 12)
            .clipShape(Capsule())
            .offset(y: 8)
            .rotationEffect(.degrees(isOpen ? -72 : 0), anchor: .leading)
        }
        .frame(width: 228, height: 90, alignment: .bottomLeading)
        .accessibilityHidden(true)
    }
}
