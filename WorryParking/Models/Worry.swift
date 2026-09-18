import Foundation
import SwiftData

enum WorryStatus: String, Codable {
    case parked
    case reviewed
}

enum FearResult: String, Codable, CaseIterable, Identifiable {
    case happened
    case partly
    case didNotHappen
    case notYet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .happened: "It happened"
        case .partly: "Partly"
        case .didNotHappen: "It didn't happen"
        case .notYet: "Too early to tell"
        }
    }

    var symbol: String {
        switch self {
        case .happened: "exclamationmark.triangle"
        case .partly: "circle.lefthalf.filled"
        case .didNotHappen: "checkmark.seal"
        case .notYet: "hourglass"
        }
    }
}

enum WorryOutcome: String, Codable {
    case letGo
    case plan

    var title: String {
        switch self {
        case .letGo: "Let it go"
        case .plan: "Made a plan"
        }
    }
}

enum Intensity {
    static func label(_ level: Int) -> String {
        switch level {
        case ...0: "Gone"
        case 1: "A whisper"
        case 2: "Nagging"
        case 3: "Loud"
        case 4: "Heavy"
        default: "Overwhelming"
        }
    }
}

@Model
final class Worry {
    var ticketID: UUID = UUID()
    var text: String = ""
    var spotNumber: Int = 1
    var intensityBefore: Int = 3
    var parkedAt: Date = Date.now
    var exitAt: Date = Date.now
    var statusRaw: String = WorryStatus.parked.rawValue
    var fearResultRaw: String?
    var outcomeRaw: String?
    var intensityAfter: Int?
    var actionStep: String?
    var reviewedAt: Date?
    var reparkCount: Int = 0

    init(text: String, spotNumber: Int, intensityBefore: Int, exitAt: Date) {
        self.ticketID = UUID()
        self.text = text
        self.spotNumber = spotNumber
        self.intensityBefore = intensityBefore
        self.parkedAt = .now
        self.exitAt = exitAt
        self.statusRaw = WorryStatus.parked.rawValue
    }

    var status: WorryStatus {
        get { WorryStatus(rawValue: statusRaw) ?? .parked }
        set { statusRaw = newValue.rawValue }
    }

    var fearResult: FearResult? {
        get { fearResultRaw.flatMap(FearResult.init(rawValue:)) }
        set { fearResultRaw = newValue?.rawValue }
    }

    var outcome: WorryOutcome? {
        get { outcomeRaw.flatMap(WorryOutcome.init(rawValue:)) }
        set { outcomeRaw = newValue?.rawValue }
    }

    var ticketNumber: String {
        String(ticketID.uuidString.prefix(6))
    }

    func isReady(at date: Date = .now) -> Bool {
        status == .parked && exitAt <= date
    }

    /// Lowest spot number that is not currently occupied.
    static func nextFreeSpot(occupied: [Int]) -> Int {
        let taken = Set(occupied)
        var candidate = 1
        while taken.contains(candidate) { candidate += 1 }
        return candidate
    }
}
