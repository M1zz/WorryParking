import Foundation

enum AppConfig {
    /// Free users can park this many worries at once. Pro is unlimited.
    static let freeSpotLimit = 3
    /// Length of a Worry Time session at the exit gate.
    static let worrySessionMinutes = 15

    /// Apple's standard EULA. Hosted pages live in `docs/` (GitHub Pages).
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyURL = URL(string: "https://m1zz.github.io/WorryParking/privacy.html")!
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
