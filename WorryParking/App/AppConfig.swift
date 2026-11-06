import Foundation

enum AppConfig {
    /// Free users can park this many worries at once. Pro is unlimited.
    /// Until the store has sold Pro on this device, nothing is limited (→ `StoreManager.sellsPro`).
    static let freeSpotLimit = 5
    /// Length of a Worry Time session at the exit gate.
    static let worrySessionMinutes = 15

    /// Apple's standard EULA. Hosted pages live in `docs/` (GitHub Pages).
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// Crisis lines by country (Find A Helpline, ThroughLine). Never locked behind Pro.
    static let helplineURL = URL(string: "https://findahelpline.com")!
    static var privacyURL: URL {
        let language = Bundle.main.preferredLocalizations.first == "ko" ? "ko" : "en"
        return URL(string: "https://m1zz.github.io/WorryParking/\(language)/privacy.html")!
    }
}

enum SettingsKey {
    static let hasOnboarded = "hasOnboarded"
    static let worryHour = "worryTimeHour"
    static let worryMinute = "worryTimeMinute"
    static let askedFirstExitFeedback = "askedFirstExitFeedback"
}

extension String {
    var capitalizedFirst: String {
        prefix(1).uppercased() + dropFirst()
    }
}
