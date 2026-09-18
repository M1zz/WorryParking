import SwiftUI

enum Theme {
    static let asphalt = Color(red: 0.10, green: 0.11, blue: 0.13)
    static let asphaltLight = Color(red: 0.16, green: 0.17, blue: 0.20)
    static let lineYellow = Color(red: 1.00, green: 0.80, blue: 0.22)
    static let ticketPaper = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let ink = Color(red: 0.13, green: 0.13, blue: 0.16)
    static let signBlue = Color(red: 0.15, green: 0.40, blue: 0.85)
    static let readyGreen = Color(red: 0.32, green: 0.82, blue: 0.56)
}

extension FearResult {
    var color: Color {
        switch self {
        case .happened: Color(red: 0.96, green: 0.45, blue: 0.40)
        case .partly: Color.orange
        case .didNotHappen: Theme.readyGreen
        case .notYet: Color.gray
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.lineYellow

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.ink)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .background(tint, in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// The blue "P" road sign used as the brand mark.
struct ParkingSign: View {
    var size: CGFloat = 44

    var body: some View {
        Text("P")
            .font(.system(size: size * 0.62, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(Theme.signBlue, in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                    .strokeBorder(.white, lineWidth: max(1.5, size * 0.05))
                    .padding(size * 0.07)
            )
            .accessibilityHidden(true)
    }
}
