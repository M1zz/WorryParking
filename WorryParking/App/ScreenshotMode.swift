#if DEBUG
import SwiftUI
import SwiftData

/// App Store screenshot mode. Launch with `-screenshotScene <scene>` to open a
/// seeded, in-memory lot with Pro unlocked. Never touches the real store.
enum ScreenshotScene: String {
    case lot, park, ticket, gate, log

    static var current: ScreenshotScene? {
        UserDefaults.standard.string(forKey: "screenshotScene").flatMap(Self.init(rawValue:))
    }
}

struct ScreenshotRootView: View {
    let scene: ScreenshotScene

    @State private var store = StoreManager()
    @State private var data = ScreenshotData()

    var body: some View {
        content
            .environment(store)
            .modelContainer(data.container)
            .onAppear { store.unlockForScreenshots() }
    }

    @ViewBuilder
    private var content: some View {
        switch scene {
        case .lot:
            MainTabView()
        case .log:
            MainTabView(selection: 1)
        case .park:
            MainTabView()
                .sheet(isPresented: .constant(true)) {
                    ParkWorryView(spot: data.draftSpot, draft: data.draftText, intensity: 4)
                }
        case .ticket:
            MainTabView()
                .sheet(isPresented: .constant(true)) {
                    ParkedTicketSheet(worry: data.hidden)
                }
        case .gate:
            MainTabView()
                .fullScreenCover(isPresented: .constant(true)) {
                    ExitGateView(worry: data.ready, fearResult: .didNotHappen)
                }
        }
    }
}

@MainActor
struct ScreenshotData {
    let container: ModelContainer
    let ready: Worry
    let hidden: Worry
    let draftSpot = 4
    let draftText: String

    // 예시 걱정은 ScreenshotSamples.xcstrings 에서 언어별로 가져온다 (스크린샷 언어마다 번역).

    init() {
        container = try! ModelContainer(
            for: Worry.self, ExperienceFeedback.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let now = Date.now
        let hour: TimeInterval = 60 * 60
        let nextWorryTime = WorryTime.next(hour: WorryTime.defaultHour, minute: WorryTime.defaultMinute)

        func make(
            _ text: String, spot: Int, level: Int, ticket: String,
            parkedAgo: TimeInterval, exitAt: Date
        ) -> Worry {
            let worry = Worry(text: text, spotNumber: spot, intensityBefore: level, exitAt: exitAt)
            worry.ticketID = UUID(uuidString: ticket + "00-0000-4000-8000-000000000000") ?? UUID()
            worry.parkedAt = now.addingTimeInterval(-parkedAgo)
            context.insert(worry)
            return worry
        }

        // Parked lot
        ready = make(
            String(localized: "My manager's reply was so short. Did I do something wrong?", table: "ScreenshotSamples"),
            spot: 1, level: 4, ticket: "A7F3C2", parkedAgo: 19 * hour, exitAt: now.addingTimeInterval(-600)
        )
        _ = make(
            String(localized: "Can I actually cover this month's card bill?", table: "ScreenshotSamples"),
            spot: 2, level: 3, ticket: "3B9E14", parkedAgo: 1 * hour, exitAt: nextWorryTime
        )
        hidden = make(
            String(localized: "Mom's checkup results still aren't back. What if they found something serious and she's not telling me?", table: "ScreenshotSamples"),
            spot: 3, level: 5, ticket: "C45D80", parkedAgo: 3 * hour,
            exitAt: WorryTime.sameTimeNextDay(after: nextWorryTime)
        )
        _ = make(
            String(localized: "It feels like my friends ignore only my messages in the group chat.", table: "ScreenshotSamples"),
            spot: 5, level: 2, ticket: "5E0A6F", parkedAgo: 2 * hour, exitAt: nextWorryTime
        )

        draftText = String(localized: "What if I blank during tomorrow's presentation and everyone decides I'm not good enough?", table: "ScreenshotSamples")

        // Exit log
        typealias Review = (text: String, before: Int, after: Int, result: FearResult, step: String?)
        let reviews: [Review] = [
            (String(localized: "I'll never make the report deadline.", table: "ScreenshotSamples"), 4, 1, .didNotHappen, nil),
            (String(localized: "If I stutter in the interview, I'm out.", table: "ScreenshotSamples"), 5, 2, .partly,
             String(localized: "Practice three likely questions out loud", table: "ScreenshotSamples")),
            (String(localized: "My landlord is going to raise the rent.", table: "ScreenshotSamples"), 3, 2, .happened,
             String(localized: "Check rents in the neighborhood", table: "ScreenshotSamples")),
            (String(localized: "Missing the flight would ruin the whole trip.", table: "ScreenshotSamples"), 4, 0, .didNotHappen, nil),
            (String(localized: "My sister must be hurt by what I said.", table: "ScreenshotSamples"), 3, 1, .didNotHappen, nil),
            (String(localized: "What if the checkup finds something?", table: "ScreenshotSamples"), 5, 1, .didNotHappen, nil),
            (String(localized: "I think I blew this quarter's review.", table: "ScreenshotSamples"), 4, 3, .notYet,
             String(localized: "Ask my manager for a 1:1", table: "ScreenshotSamples")),
            (String(localized: "Did my joke at dinner go too far?", table: "ScreenshotSamples"), 3, 0, .didNotHappen, nil),
            (String(localized: "If my laptop dies, I lose everything.", table: "ScreenshotSamples"), 2, 1, .didNotHappen,
             String(localized: "Turn on cloud backup", table: "ScreenshotSamples")),
            (String(localized: "I'll get called out again at Monday's meeting.", table: "ScreenshotSamples"), 4, 2, .didNotHappen, nil),
        ]
        let spots = [2, 1, 3, 1, 2, 4, 1, 3, 2, 1]
        let tickets = ["D1E2F3", "0A1B2C", "E4F5A6", "7B8C9D", "F0E1D2", "2C3D4E", "B5A697", "6F7E8D", "A1B2C3", "8D9E0F"]
        for (index, review) in reviews.enumerated() {
            let reviewedAt = now.addingTimeInterval(-Double(index + 1) * 2.3 * 24 * hour)
            let worry = make(
                review.text,
                spot: spots[index], level: review.before, ticket: tickets[index],
                parkedAgo: now.timeIntervalSince(reviewedAt) + 20 * hour, exitAt: reviewedAt
            )
            worry.fearResult = review.result
            worry.intensityAfter = review.after
            worry.outcome = review.step == nil ? .letGo : .plan
            worry.actionStep = review.step
            worry.reviewedAt = reviewedAt
            worry.status = .reviewed
        }

        try? context.save()
    }
}
#endif
