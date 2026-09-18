import Foundation

enum AppConfig {
    /// Free users can park this many worries at once. Pro is unlimited.
    static let freeSpotLimit = 3
    /// Length of a Worry Time session at the exit gate.
    static let worrySessionMinutes = 15

    // TODO: Replace with your own hosted documents before App Store submission.
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://example.com/worry-parking/privacy")!
}

enum SettingsKey {
    static let hasOnboarded = "hasOnboarded"
    static let worryHour = "worryTimeHour"
    static let worryMinute = "worryTimeMinute"
}

extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
