import Foundation

struct ResultCount: Identifiable {
    let result: FearResult
    let count: Int
    var id: FearResult { result }
}

struct InsightsSummary {
    let total: Int
    let didNotHappenRate: Double?
    let averageDrop: Double?
    let resultCounts: [ResultCount]

    init(worries: [Worry]) {
        total = worries.count

        let results = worries.compactMap(\.fearResult)
        resultCounts = FearResult.allCases.map { result in
            ResultCount(result: result, count: results.filter { $0 == result }.count)
        }

        let decided = results.filter { $0 != .notYet }
        if decided.isEmpty {
            didNotHappenRate = nil
        } else {
            didNotHappenRate = Double(decided.filter { $0 == .didNotHappen }.count) / Double(decided.count)
        }

        let drops: [Double] = worries.compactMap { worry in
            guard let after = worry.intensityAfter else { return nil }
            return Double(worry.intensityBefore - after)
        }
        averageDrop = drops.isEmpty ? nil : drops.reduce(0, +) / Double(drops.count)
    }

    var headline: String {
        guard let rate = didNotHappenRate else {
            return String(localized: "Keep parking. Patterns show up after a few exits.")
        }
        let percent = Int((rate * 100).rounded())
        return String(localized: "\(percent)% of the fears you checked didn't come true.")
    }
}
