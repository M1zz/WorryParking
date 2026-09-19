import SwiftUI
import StoreKit
import UIKit
import UserNotifications

struct SettingsView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute

    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showingPaywall = false
    @State private var showingManageSubscription = false

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

                Section("Worry Parking Pro") {
                    if store.isPro {
                        Label("Pro is active", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Theme.readyGreen)
                        Button("Manage subscription") { showingManageSubscription = true }
                    } else {
                        Button {
                            showingPaywall = true
                        } label: {
                            Label("Unlimited spots, custom exit times, insights", systemImage: "sparkles")
                        }
                    }
                    Button("Restore purchases") {
                        Task { await store.restorePurchases() }
                    }
                }

                Section("About") {
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
                    Link("Terms of Use", destination: AppConfig.termsURL)
                    Link("Privacy Policy", destination: AppConfig.privacyURL)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.asphalt.ignoresSafeArea())
            .navigationTitle("Settings")
            .toolbarBackground(Theme.asphalt, for: .navigationBar)
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .manageSubscriptionsSheet(isPresented: $showingManageSubscription)
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
