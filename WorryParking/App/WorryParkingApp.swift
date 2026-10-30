import SwiftUI
import SwiftData
import LeeoKit

@main
struct WorryParkingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(Theme.lineYellow)
                .task { await store.start() }
                // 팁 상품을 불러오고 끝나지 않은 팁을 마저 센다 (LeeoStore 없이 혼자)
                .task { await WorryParkingSpec.tipJar.startStandalone() }
                // 아이폰 듀오: 접힘을 재서 아래로 흘린다. 시트 · 알림창도 접힌 선을 비킨다.
                .foldAware()
        }
        .modelContainer(for: [Worry.self, ExperienceFeedback.self])
    }
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
