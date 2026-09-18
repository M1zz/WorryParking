import SwiftUI
import SwiftData

struct ParkingRequest: Identifiable {
    let spot: Int
    var id: Int { spot }
}

struct ParkingLotView: View {
    @Environment(StoreManager.self) private var store
    @AppStorage(SettingsKey.worryHour) private var worryHour = WorryTime.defaultHour
    @AppStorage(SettingsKey.worryMinute) private var worryMinute = WorryTime.defaultMinute

    @Query(filter: #Predicate<Worry> { $0.statusRaw == "parked" }, sort: \Worry.exitAt)
    private var parked: [Worry]

    @State private var parkingRequest: ParkingRequest?
    @State private var inspecting: Worry?
    @State private var exiting: Worry?
    @State private var showingPaywall = false

    private var isAtFreeLimit: Bool {
        !store.isPro && parked.count >= AppConfig.freeSpotLimit
    }

    private var spotCount: Int {
        let highest = parked.map(\.spotNumber).max() ?? 0
        let needed: Int
        if store.isPro {
            needed = max(6, parked.count + 2, highest)
        } else {
            // Free lot shows its spots plus one locked "Pro" teaser spot.
            needed = max(AppConfig.freeSpotLimit + 1, highest)
        }
        return needed + (needed % 2)
    }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 15)) { context in
                lotContent(now: context.date)
            }
            .background(Theme.asphalt.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { parkButton }
            .navigationTitle("Worry Parking")
            .toolbarBackground(Theme.asphalt, for: .navigationBar)
            .sheet(item: $parkingRequest) { request in
                ParkWorryView(spot: request.spot)
            }
            .sheet(item: $inspecting) { worry in
                ParkedTicketSheet(worry: worry)
            }
            .fullScreenCover(item: $exiting) { worry in
                ExitGateView(worry: worry)
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Sections

    private func lotContent(now: Date) -> some View {
        let ready = parked.filter { $0.exitAt <= now }
        return ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header(now: now)
                if !ready.isEmpty {
                    readySection(ready)
                }
                lotGrid(now: now)
                Text("Parked worries stay hidden until their exit time. You don't have to carry them right now.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }

    private func header(now: Date) -> some View {
        let next = WorryTime.next(hour: worryHour, minute: worryMinute, after: now, minimumLead: 0)
        let usage: String = store.isPro
            ? String(localized: "\(parked.count) parked")
            : String(localized: "\(parked.count) of \(AppConfig.freeSpotLimit) spots used")
        return HStack(spacing: 14) {
            ParkingSign(size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(usage)
                    .font(.headline)
                Text("Next Worry Time: \(WorryTime.describe(next))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func readySection(_ ready: [Worry]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ready for pickup", systemImage: "bell.badge.fill")
                .font(.headline)
                .foregroundStyle(Theme.readyGreen)
            ForEach(ready) { worry in
                Button {
                    exiting = worry
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "car.side.fill")
                            .font(.title2)
                            .foregroundStyle(Theme.readyGreen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("P\(worry.spotNumber) · Ticket #\(worry.ticketNumber)")
                                .font(.subheadline.weight(.semibold))
                            Text("Parked \(worry.parkedAt.formatted(.relative(presentation: .named)))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("Exit gate")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Theme.readyGreen, in: Capsule())
                    }
                    .padding(14)
                    .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func lotGrid(now: Date) -> some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 18) {
            ForEach(1...spotCount, id: \.self) { number in
                let worry = parked.first { $0.spotNumber == number }
                let locked = worry == nil && !store.isPro && number > AppConfig.freeSpotLimit
                Button {
                    handleTap(spot: number, worry: worry, locked: locked, now: now)
                } label: {
                    ParkingSpotView(number: number, worry: worry, isLocked: locked, now: now)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var parkButton: some View {
        Button {
            startParking(at: nil)
        } label: {
            Label("Park a worry", systemImage: "parkingsign")
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(
            LinearGradient(colors: [Theme.asphalt.opacity(0), Theme.asphalt], startPoint: .top, endPoint: .center)
                .ignoresSafeArea()
        )
    }

    // MARK: - Actions

    private func handleTap(spot: Int, worry: Worry?, locked: Bool, now: Date) {
        if let worry {
            if worry.exitAt <= now {
                exiting = worry
            } else {
                inspecting = worry
            }
        } else if locked {
            showingPaywall = true
        } else {
            startParking(at: spot)
        }
    }

    private func startParking(at spot: Int?) {
        guard !isAtFreeLimit else {
            showingPaywall = true
            return
        }
        let target = spot ?? Worry.nextFreeSpot(occupied: parked.map(\.spotNumber))
        parkingRequest = ParkingRequest(spot: target)
    }
}

struct ParkingSpotView: View {
    let number: Int
    let worry: Worry?
    let isLocked: Bool
    let now: Date

    var body: some View {
        VStack(spacing: 10) {
            Text("P\(number)")
                .font(.caption.weight(.heavy).monospaced())
                .foregroundStyle(Theme.lineYellow)
            content
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .padding(.horizontal, 10)
        .overlay(SpotLines().stroke(Theme.lineYellow.opacity(0.85), lineWidth: 3))
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    @ViewBuilder
    private var content: some View {
        if let worry {
            let ready = worry.exitAt <= now
            Image(systemName: "car.side.fill")
                .font(.system(size: 40))
                .foregroundStyle(ready ? Theme.readyGreen : Color.white.opacity(0.9))
                .symbolEffect(.pulse, isActive: ready)
            if ready {
                Text("Ready for pickup")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.readyGreen)
            } else {
                Text("Exits in \(Text(worry.exitAt, style: .relative))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        } else if isLocked {
            Image(systemName: "lock.fill")
                .font(.title2)
                .foregroundStyle(Color.white.opacity(0.4))
            Text("Pro spot")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "plus")
                .font(.title2)
                .foregroundStyle(Color.white.opacity(0.3))
            Text("Empty")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var accessibilityText: String {
        if let worry {
            if worry.exitAt <= now {
                return String(localized: "Spot \(number). Worry ready for pickup.")
            }
            return String(localized: "Spot \(number). Worry parked until \(WorryTime.describe(worry.exitAt)).")
        }
        return isLocked
            ? String(localized: "Spot \(number). Pro spot, locked.")
            : String(localized: "Spot \(number). Empty. Park a worry here.")
    }
}
