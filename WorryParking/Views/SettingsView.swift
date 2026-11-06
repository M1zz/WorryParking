import SwiftUI
import UIKit
import LeeoKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        "Worry Time",
                        selection: WorryTime.dateBinding(hour: $worryHour, minute: $worryMinute),
                        displayedComponents: .hourAndMinute
                    )
                } footer: {
                    Text("Choose a time a few hours before bed. New worries are parked until then. Already-parked worries keep their exit time.")
                }

                Section("Reminders") {
                    notificationRow
                }

                ProSettingsSection()

                // 개발자 응원하기 — 판매 중인 팁이 있어야 선다.
                Section {
                    LeeoTipJarLink<WorryParkingSpec>(tipJar: WorryParkingSpec.tipJar)
                }

                Section("About") {
                    NavigationLink { LeeoVaultView(appName: WorryParkingSpec.displayName) } label: {
                        Label(LeeoVaultText.entry, systemImage: "externaldrive.badge.timemachine")
                    }
                    NavigationLink {
                        WhyItWorksView()
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        Label("Why it works", systemImage: "brain.head.profile")
                    }
                    Text("Worry Parking is built on worry postponement, a stimulus-control technique used in cognitive behavioral therapy (CBT): instead of fighting a worry, you schedule it for a set time and return to it then.")
                        .font(.footnote)
                    Text("Everything you write stays on this device. Notifications never include your worry text.")
                        .font(.footnote)
                    Text("Worry Parking is a self-help tool, not a medical device or a substitute for professional care. If you're struggling, please reach out to a mental health professional or local emergency services.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    // 안전 안내 — 누구에게나 연다. 나라마다 맞는 상담 전화를 모아 둔 곳으로 보낸다.
                    Link(destination: AppConfig.helplineURL) {
                        Label("Find a helpline near you", systemImage: "phone.bubble")
                    }
                    Link("Terms of Use", destination: AppConfig.termsURL)
                    Link("Privacy Policy", destination: AppConfig.privacyURL)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.asphalt.ignoresSafeArea())
            // 펼친 아이폰 듀오의 탭 막대 자리 (NavigationStack 안에서 비운다)
            .foldTabBarRoom()
            .navigationTitle("Settings")
            .toolbarBackground(Theme.asphalt, for: .navigationBar)
            .task { await refreshNotificationStatus() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task { await refreshNotificationStatus() }
                }
            }
        }
    }

    @ViewBuilder
    private var notificationRow: some View {
        switch notificationStatus {
        case .authorized, .provisional, .ephemeral:
            Label("We'll tell you when a worry is ready for pickup.", systemImage: "bell.fill")
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Label("Notifications are off", systemImage: "bell.slash.fill")
                Text("Without them, parked worries wait silently in the lot.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Open iOS Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            }
        default:
            Button("Allow pickup reminders") {
                Task {
                    await NotificationManager.requestAuthorization()
                    await refreshNotificationStatus()
                }
            }
        }
    }

    private func refreshNotificationStatus() async {
        notificationStatus = await NotificationManager.authorizationStatus()
    }
}
