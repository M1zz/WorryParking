import SwiftUI
import SwiftData
import AppIntents
import LeeoKit

@main
struct WorryParkingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = StoreManager.shared

    init() {
        // 백업 금고: 예약된 복원 · 업데이트 직전 백업을 저장소가 열리기 전에 한다
        LeeoVault.start(WorryParkingSpec.self)
        // Siri 인텐트가 같은 저장소를 쓴다 (→ WorryIntents.swift)
        AppDependencyManager.shared.add(dependency: Self.container)
        #if DEBUG
        CloudKitSchemaWarmup.runIfRequested(Self.container) {
            [Worry(text: "표본", spotNumber: 1, intensityBefore: 3, exitAt: .now),
             ExperienceFeedback(moment: .trial, feeling: .same, levelBefore: 0, levelAfter: 0, note: "")]
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                // 개발자가 보낸 의견에 답장하면, 앱이 앞으로 올 때 답장을 시트로 보여 준다 (LeeoKit).
                .leeoFeedbackReplyNotice(WorryParkingSpec.self)
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(Theme.lineYellow)
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다 (LeeoStore 없이 혼자)
                .task { await WorryParkingSpec.tipJar.startStandalone() }
                // 아이폰 듀오: 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다.
                .foldAware()
                .storeFallbackNotice()
        }
        .modelContainer(Self.container)
    }

    /// `.modelContainer(for:)` 는 저장소를 못 열면 앱을 죽인다 — 그러면 켤 때마다 죽고 고칠 길도 없다.
    /// 손으로 열고, 실패하면 디스크의 기록은 그대로 둔 채 이번 실행만 메모리에서 연다.
    private static let container: ModelContainer = {
        let schema = Schema([Worry.self, ExperienceFeedback.self])
        // 1. 사용자의 iCloud(앱 자체 컨테이너의 개인 데이터베이스). 기기에 있던 기록은 그대로 올라가고,
        //    새 기기는 계정에 있던 것을 받아 온다. 컨테이너를 이름으로 못박는다 — 비워 두면(.automatic)
        //    entitlements 의 첫 컨테이너(FeedbackHub, 피드백 전송용)로 걱정이 올라간다.
        if let synced = try? ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .private(cloudContainer))
        ) {
            usesCloud = true
            return synced
        }
        // 2. 같은 파일을 기기 안에서만. entitlement 가 없거나 컨테이너가 아직 없는 빌드도 기록은 잃지 않는다.
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, cloudKitDatabase: .none))
        } catch {
            return StoreFallback.memoryContainer(schema: schema, after: error)
        }
    }()

    /// 앱 자체 iCloud 컨테이너. entitlements 에 이 이름이 있어야 1 단계가 열린다.
    static let cloudContainer = "iCloud.com.devkoan.worryparking"
    /// 이번 실행이 iCloud 와 이어져 열렸는가 (makeContainer 가 한 번 정한다).
    private(set) static var usesCloud = false
}

struct RootView: View {
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        #if DEBUG
        if let scene = ScreenshotScene.current {
            ScreenshotRootView(scene: scene)
        } else {
            appRoot
        }
        #else
        appRoot
        #endif
    }

    @ViewBuilder
    private var appRoot: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            OnboardingView()
                .foldConfined()
        }
    }
}

/// 아이폰 듀오를 펴면(이 앱은 세로 고정) 아래 판은 주차장 · 설정, 위 판은 출차 기록.
/// 주차해 두는 쪽과 그 걱정이 어떻게 됐는지 보는 쪽이 접힌 선을 사이에 둔다.
/// 출차 기록은 늘 위 판에 있으므로 펼친 탭 막대에는 주차장 · 설정만 선다.
/// 접혀 있거나 보통 아이폰이면 탭 셋 그대로다.
struct MainTabView: View {
    @State var selection = 0
    @Environment(\.foldLayout) private var fold
    @Environment(\.scenePhase) private var scenePhase
    @Environment(StoreManager.self) private var store
    @State private var showingGraduation = false

    var body: some View {
        TabView(selection: $selection) {
            foldTab { ParkingLotView() }
                .tabItem { Label("Lot", systemImage: "parkingsign") }
                .tag(0)
            ExitLogView()
                .tabItem { Label("Exit Log", systemImage: "list.bullet.rectangle") }
                .tag(1)
            foldTab { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
        .foldTabBar(items: [
            .init(value: 0, title: String(localized: "Lot"), symbol: "parkingsign"),
            .init(value: 2, title: String(localized: "Settings"), symbol: "gearshape"),
        ], selected: selection) { selection = $0 }
        // 출차 기록 탭에서 펴면 주차장으로 옮긴다. 출차 기록은 위 판에 그대로 있다.
        .onChange(of: fold.isUnfolded, initial: true) { _, unfolded in
            if unfolded, selection == 1 { selection = 0 }
        }
        // 앱을 열 때와 다시 앞에 올 때 영수증을 읽는다. 구독 졸업을 제안할 때면 한 번 띄운다.
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            await store.refresh()
            if store.graduationIsDue {
                store.markGraduationOffered()
                showingGraduation = true
            }
        }
        .sheet(isPresented: $showingGraduation) { ProGraduationSheet() }
    }

    private func foldTab<Choose: View>(@ViewBuilder _ choose: () -> Choose) -> some View {
        FoldSplitView {
            // 탭 막대 자리(.foldTabBarRoom)는 각 화면의 NavigationStack 안에서 비운다.
            // 밖에서 걸면 주차장 바닥의 '걱정 주차하기' 버튼이 올라가지 않고 막대 밑에 깔린다.
            choose()
        } result: {
            // 위 판 안에서는 접히지 않은 화면처럼 선다.
            ExitLogView().environment(\.foldLayout, .single)
        }
    }
}
