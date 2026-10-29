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
        }
    }
}

struct MainTabView: View {
    @State var selection = 0

    var body: some View {
        TabView(selection: $selection) {
            ParkingLotView()
                .tabItem { Label("Lot", systemImage: "parkingsign") }
                .tag(0)
            ExitLogView()
                .tabItem { Label("Exit Log", systemImage: "list.bullet.rectangle") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(2)
        }
    }
}
