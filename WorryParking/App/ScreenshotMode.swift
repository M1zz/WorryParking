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

    private static var isKorean: Bool {
        Locale.current.language.languageCode == .korean
    }

    private static func pick(_ en: String, _ ko: String) -> String {
        isKorean ? ko : en
    }

    init() {
        container = try! ModelContainer(
            for: Worry.self,
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
            Self.pick("My manager's reply was so short. Did I do something wrong?",
                      "팀장님 답장이 너무 짧았어. 내가 뭘 잘못한 걸까?"),
            spot: 1, level: 4, ticket: "A7F3C2", parkedAgo: 19 * hour, exitAt: now.addingTimeInterval(-600)
        )
        _ = make(
            Self.pick("Can I actually cover this month's card bill?",
                      "이번 달 카드값을 감당할 수 있을까?"),
            spot: 2, level: 3, ticket: "3B9E14", parkedAgo: 1 * hour, exitAt: nextWorryTime
        )
        hidden = make(
            Self.pick("Mom's checkup results still aren't back. What if they found something serious and she's not telling me?",
                      "엄마 건강검진 재검 결과가 아직 안 나왔어. 혹시 큰 병인데 나한테 말을 안 하시는 거면 어떡하지?"),
            spot: 3, level: 5, ticket: "C45D80", parkedAgo: 3 * hour,
            exitAt: WorryTime.sameTimeNextDay(after: nextWorryTime)
        )
        _ = make(
            Self.pick("It feels like my friends ignore only my messages in the group chat.",
                      "단톡방에서 친구들이 내 말만 무시하는 것 같아."),
            spot: 5, level: 2, ticket: "5E0A6F", parkedAgo: 2 * hour, exitAt: nextWorryTime
        )

        draftText = Self.pick(
            "What if I blank during tomorrow's presentation and everyone decides I'm not good enough?",
            "내일 발표하다 머리가 하얘지면, 다들 내가 무능하다고 생각할 거야."
        )

        // Exit log
        typealias Review = (en: String, ko: String, before: Int, after: Int, result: FearResult, step: (en: String, ko: String)?)
        let reviews: [Review] = [
            ("I'll never make the report deadline.", "보고서 마감을 못 맞추면 어쩌지.", 4, 1, .didNotHappen, nil),
            ("If I stutter in the interview, I'm out.", "면접에서 말을 더듬으면 떨어질 거야.", 5, 2, .partly,
             ("Practice three likely questions out loud", "예상 질문 3개 소리 내어 연습하기")),
            ("My landlord is going to raise the rent.", "집주인이 월세를 올릴 것 같아.", 3, 2, .happened,
             ("Check rents in the neighborhood", "주변 시세 알아보기")),
            ("Missing the flight would ruin the whole trip.", "비행기를 놓치면 여행을 다 망칠 거야.", 4, 0, .didNotHappen, nil),
            ("My sister must be hurt by what I said.", "동생이 내 말에 서운했을 거야.", 3, 1, .didNotHappen, nil),
            ("What if the checkup finds something?", "건강검진에서 뭐라도 나오면 어떡하지.", 5, 1, .didNotHappen, nil),
            ("I think I blew this quarter's review.", "이번 분기 평가를 망친 것 같아.", 4, 3, .notYet,
             ("Ask my manager for a 1:1", "팀장님께 1:1 요청하기")),
            ("Did my joke at dinner go too far?", "모임에서 한 농담이 선을 넘었나?", 3, 0, .didNotHappen, nil),
            ("If my laptop dies, I lose everything.", "노트북이 고장 나면 작업물이 다 날아가.", 2, 1, .didNotHappen,
             ("Turn on cloud backup", "클라우드 백업 켜기")),
            ("I'll get called out again at Monday's meeting.", "월요일 회의에서 또 지적받을 거야.", 4, 2, .didNotHappen, nil),
        ]
        let spots = [2, 1, 3, 1, 2, 4, 1, 3, 2, 1]
        let tickets = ["D1E2F3", "0A1B2C", "E4F5A6", "7B8C9D", "F0E1D2", "2C3D4E", "B5A697", "6F7E8D", "A1B2C3", "8D9E0F"]
        for (index, review) in reviews.enumerated() {
            let reviewedAt = now.addingTimeInterval(-Double(index + 1) * 2.3 * 24 * hour)
            let worry = make(
                Self.pick(review.en, review.ko),
                spot: spots[index], level: review.before, ticket: tickets[index],
                parkedAgo: now.timeIntervalSince(reviewedAt) + 20 * hour, exitAt: reviewedAt
            )
            worry.fearResult = review.result
            worry.intensityAfter = review.after
            worry.outcome = review.step == nil ? .letGo : .plan
            worry.actionStep = review.step.map { Self.pick($0.en, $0.ko) }
            worry.reviewedAt = reviewedAt
            worry.status = .reviewed
        }

        try? context.save()
    }
}
#endif
