import SwiftUI

struct OnboardingView: View {
    @AppStorage(SettingsKey.hasOnboarded) private var hasOnboarded = false
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute

    @State private var page = 0
    /// Reminders are requested when leaving this page, so the prompt never
    /// interrupts the trial that follows.
    private let worryTimePageIndex = 3
    /// The last page is the hands-on trial, which brings its own buttons.
    private let trialPage = 4

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                welcomePage.tag(0)
                WhyItWorksView().tag(1)
                ExampleWalkthrough().tag(2)
                worryTimePage.tag(worryTimePageIndex)
                OnboardingTrialView {
                    Task { await finish() }
                }
                .tag(trialPage)
            }
            // Dots are drawn below instead, so they never sit on top of scrolling text.
            .tabViewStyle(.page(indexDisplayMode: .never))

            if page < trialPage {
                pageDots
                    .padding(.top, 12)
                Button {
                    if page == worryTimePageIndex {
                        Task {
                            await NotificationManager.requestAuthorization()
                            withAnimation { page += 1 }
                        }
                    } else {
                        withAnimation { page += 1 }
                    }
                } label: {
                    if page == worryTimePageIndex {
                        Text("Allow reminders & continue")
                    } else {
                        Text("Continue")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(24)
            }
        }
        .background(Theme.asphalt.ignoresSafeArea())
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0...trialPage, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Theme.lineYellow : Color.white.opacity(0.25))
                    .frame(width: index == page ? 20 : 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: page)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Page \(page + 1) of \(trialPage + 1)"))
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

    /// Scrolls so the wheel picker never squeezes the explanation into "…";
    /// stays vertically centered when everything fits.
    private var worryTimePage: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(Theme.lineYellow)
                            .accessibilityHidden(true)
                        Text("Pick your Worry Time")
                            .font(.largeTitle.weight(.bold))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("A daily 15-minute window, ideally a few hours before bed. We'll tap you on the shoulder when a worry is ready for pickup.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)

                    // The wheel won't shrink below ~320pt, so it gets the full
                    // page width instead of the text margins.
                    DatePicker(
                        "Worry Time",
                        selection: WorryTime.dateBinding(hour: $worryHour, minute: $worryMinute),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(width: proxy.size.width)
                    .clipped()
                }
                .padding(.vertical, 28)
                // Pinned to the page width: anything wider would push the
                // whole page to the right instead of staying centered.
                .frame(width: proxy.size.width)
                .frame(minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func finish() async {
        await NotificationManager.requestAuthorization()
        withAnimation { hasOnboarded = true }
    }
}

/// A worked example of one worry going through the lot, start to finish.
/// Auto-advances until the user taps a step.
private struct ExampleWalkthrough: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var step = 0
    @State private var autoplay = true

    private let worryText = String(localized: "What if I blank during tomorrow's presentation and everyone decides I'm not good enough?")
    private let parkedAt = ExampleWalkthrough.date(daysFromToday: -1, hour: 23, minute: 40)
    private let exitAt = ExampleWalkthrough.date(daysFromToday: 0, hour: WorryTime.defaultHour, minute: 0)

    private static func date(daysFromToday days: Int, hour: Int, minute: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: days, to: .now) ?? .now
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("See it in action")
                        .font(.largeTitle.weight(.bold))
                    Text("One real worry, from 11:40 PM to Worry Time the next day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                stepPicker

                Group {
                    switch step {
                    case 0: writeStep
                    case 1: parkStep
                    default: exitStep
                    }
                }
                .id(step)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .opacity
                ))

                Text(caption)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .id("caption-\(step)")
            }
            .padding(24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .task(id: autoplay) {
            guard autoplay, !reduceMotion, !voiceOverEnabled else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(4))
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.35)) { step = (step + 1) % 3 }
            }
        }
    }

    private var stepPicker: some View {
        HStack(spacing: 8) {
            stepChip(0, title: "Write", systemImage: "pencil")
            stepChip(1, title: "Park", systemImage: "parkingsign")
            stepChip(2, title: "Exit", systemImage: "arrow.up.right")
        }
    }

    private func stepChip(_ index: Int, title: LocalizedStringKey, systemImage: String) -> some View {
        Button {
            autoplay = false
            withAnimation(.easeInOut(duration: 0.35)) { step = index }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    step == index ? Theme.lineYellow : Theme.asphaltLight,
                    in: Capsule()
                )
                .foregroundStyle(step == index ? Theme.ink : Color.white)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(step == index ? .isSelected : [])
    }

    private var caption: String {
        switch step {
        case 0:
            String(localized: "11:40 PM and your brain won't stop replaying tomorrow. Write the worry exactly as it sounds, and rate how loud it is.")
        case 1:
            String(localized: "It's parked until tomorrow's Worry Time. When it pops up again in the shower, just tell yourself: it already has a spot.")
        default:
            String(localized: "6:00 PM, the presentation is over. Did it happen? Not really. The worry dropped from 4 to 1, so you let it go, and it's added to your Exit Log.")
        }
    }

    private var writeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's circling in your head?")
                .font(.headline)
            Text(worryText)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            Text("How loud is it right now?")
                .font(.headline)
            IntensityPicker(value: .constant(4), range: 1...5)
                .allowsHitTesting(false)
        }
    }

    private var parkStep: some View {
        TicketView(
            spot: 1,
            ticketNumber: "A7F3C2",
            parkedAt: parkedAt,
            exitAt: exitAt,
            text: worryText,
            intensity: 4,
            isRevealed: false
        )
    }

    private var exitStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Exit Gate · P1", systemImage: "timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.lineYellow)
                Spacer()
                Text(exitAt, format: .dateTime.hour().minute())
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Text(worryText)
                .font(.body)
            HStack(spacing: 6) {
                Tag(text: FearResult.didNotHappen.title, color: FearResult.didNotHappen.color)
                Tag(text: String(localized: "Level \(4) → \(1)"), color: .gray)
                Tag(text: WorryOutcome.letGo.title, color: Theme.signBlue)
            }
        }
        .padding(16)
        .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
