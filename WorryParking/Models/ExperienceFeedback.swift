import Foundation
import SwiftData

/// When the user was asked how postponing felt.
enum FeedbackMoment: String, Codable {
    /// Right after parking a first worry during onboarding.
    case trial
    /// After the first worry made it through the exit gate.
    case firstExit

    var title: String {
        switch self {
        case .trial: String(localized: "First time parking")
        case .firstExit: String(localized: "First exit")
        }
    }
}

enum ExperienceFeeling: String, Codable, CaseIterable, Identifiable {
    case lighter
    case same
    case heavier

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .lighter: "wind"
        case .same: "equal.circle"
        case .heavier: "cloud.rain"
        }
    }

    func title(for moment: FeedbackMoment) -> String {
        switch (moment, self) {
        case (.trial, .lighter): String(localized: "A little lighter")
        case (.trial, .same): String(localized: "About the same")
        case (.trial, .heavier): String(localized: "It's on my mind more")
        case (.firstExit, .lighter): String(localized: "It bothered me less")
        case (.firstExit, .same): String(localized: "About the same")
        case (.firstExit, .heavier): String(localized: "It bothered me more")
        }
    }

    func response(for moment: FeedbackMoment) -> String {
        switch (moment, self) {
        case (.trial, .lighter):
            String(localized: "That's the first effect of postponing. Once a worry is written down and has a place, your mind doesn't have to hold on to it. See you at Worry Time.")
        case (.trial, .same):
            String(localized: "That's completely normal. The effect usually builds over days, not minutes. When it pops back up, tell it \"you already have a spot\" and see how it feels at Worry Time.")
        case (.trial, .heavier):
            String(localized: "Looking straight at a worry can make it feel bigger at first. You don't have to solve it now. Its only job is to wait for Worry Time.")
        case (.firstExit, .lighter):
            String(localized: "Postponing is working for you. Try parking the next one too.")
        case (.firstExit, .same):
            String(localized: "It's only the first one. In studies, the effect built up over a few weeks. Park a few more and compare them in your Exit Log.")
        case (.firstExit, .heavier):
            String(localized: "If it kept coming back, try a short \"you already have a spot\" and return to what you were doing. If worry is getting in the way of your days, talking to a professional can really help.")
        }
    }
}

/// How postponing felt, in the user's own words. Stored only on this device
/// and shown back to the user in the Exit Log.
@Model
final class ExperienceFeedback {
    var momentRaw: String = FeedbackMoment.trial.rawValue
    var feelingRaw: String = ExperienceFeeling.same.rawValue
    var levelBefore: Int = 0
    var levelAfter: Int = 0
    var note: String = ""
    var createdAt: Date = Date.now

    init(moment: FeedbackMoment, feeling: ExperienceFeeling, levelBefore: Int, levelAfter: Int, note: String) {
        self.momentRaw = moment.rawValue
        self.feelingRaw = feeling.rawValue
        self.levelBefore = levelBefore
        self.levelAfter = levelAfter
        self.note = note
        self.createdAt = .now
    }

    var moment: FeedbackMoment {
        FeedbackMoment(rawValue: momentRaw) ?? .trial
    }

    var feeling: ExperienceFeeling {
        ExperienceFeeling(rawValue: feelingRaw) ?? .same
    }
}
