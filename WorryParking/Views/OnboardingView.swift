import SwiftUI

struct OnboardingView: View {
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute

    @State private var page = 0
    private let lastPage = 2

    private var buttonTitle: String {
        page < lastPage ? "Continue" : "Allow reminders & start"
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                howItWorksPage.tag(1)
                worryTimePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                if page < lastPage {
                    withAnimation { page += 1 }
                } else {
                    Task { await finish() }
                }
            } label: {
                Text(buttonTitle)
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(24)
        }
        .background(Theme.asphalt.ignoresSafeArea())
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            ParkingSign(size: 110)
            Text("Worry Parking")
                .font(.largeTitle.weight(.heavy))
            Text("Worries don't have to ride with you all night.\nPark them here. We'll keep them until your Worry Time.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(28)
    }

    private var howItWorksPage: some View {
        VStack(alignment: .leading, spacing: 28) {
            Spacer()
            Text("How it works")
                .font(.largeTitle.weight(.bold))
            StepRow(number: 1, title: "Write it down", detail: "Get the worry out of your head and onto a ticket.")
            StepRow(number: 2, title: "Park it", detail: "It stays hidden until your daily Worry Time. If it comes back, remind yourself it already has a spot.")
            StepRow(number: 3, title: "Exit gate", detail: "At Worry Time, give it \(AppConfig.worrySessionMinutes) focused minutes. Then let it go, make a plan, or park it again.")
            Text("Based on worry postponement, a technique from cognitive behavioral therapy (CBT).")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(28)
    }

    private var worryTimePage: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "clock.fill")
                .font(.system(size: 56))
                .foregroundStyle(Theme.lineYellow)
                .accessibilityHidden(true)
            Text("Pick your Worry Time")
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Text("A daily 15-minute window, ideally a few hours before bed. We'll tap you on the shoulder when a worry is ready for pickup.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            DatePicker(
                "Worry Time",
                selection: WorryTime.dateBinding(hour: $worryHour, minute: $worryMinute),
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            Spacer()
        }
        .padding(28)
    }

    private func finish() async {
        await NotificationManager.requestAuthorization()
        withAnimation { hasOnboarded = true }
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)")
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.ink)
                .frame(width: 32, height: 32)
                .background(Theme.lineYellow, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
