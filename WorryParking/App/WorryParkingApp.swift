import SwiftUI
import SwiftData

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
        }
        .modelContainer(for: Worry.self)
    }
}

struct RootView: View {
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false

    var body: some View {
        if hasOnboarded {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            ParkingLotView()
                .tabItem { Label("Lot", systemImage: "parkingsign") }
            ExitLogView()
                .tabItem { Label("Exit Log", systemImage: "list.bullet.rectangle") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
