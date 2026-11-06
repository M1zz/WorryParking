//
//  WorryIntents.swift
//  WorryParking
//
//  "Siri, park a worry in Worry Parking" — 앱을 열지 않고 걱정을 주차한다.
//  앱에서 주차할 때와 같다: 다음 빈 자리, 다음 걱정 시간에 출차, 그때 알림.
//  무료 자리 수 제한도 앱과 똑같이 지킨다.
//

import AppIntents
import Foundation
import SwiftData

struct ParkWorryIntent: AppIntent {
    static let title = LocalizedStringResource("Park a Worry", comment: "Siri: park (set aside) a worry until worry time")
    static let description = IntentDescription(
        LocalizedStringResource("Parks a worry until your next Worry Time.", comment: "Siri: park worry description")
    )

    @Parameter(title: LocalizedStringResource("Worry", comment: "Siri: worry text parameter"),
               description: LocalizedStringResource("The worry to set aside. It stays hidden until your Worry Time.", comment: "Siri: what the worry parameter is for"),
               requestValueDialog: IntentDialog(LocalizedStringResource("What’s on your mind?", comment: "Siri: ask for the worry")))
    var worry: String

    @Dependency private var container: ModelContainer

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let text = worry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw $worry.needsValueError(IntentDialog(LocalizedStringResource("What’s on your mind?", comment: "Siri: ask for the worry")))
        }
        let context = ModelContext(container)
        let parked = ((try? context.fetch(FetchDescriptor<Worry>())) ?? []).filter { $0.status == .parked }
        if parked.count >= AppConfig.freeSpotLimit, await !Self.isPro() {
            return .result(dialog: IntentDialog(LocalizedStringResource("The lot is full. Let one worry out in the app first.", comment: "Siri: free spots used up")))
        }

        let defaults = UserDefaults.standard
        let hour = defaults.object(forKey: SettingsKey.worryHour) as? Int ?? WorryTime.defaultHour
        let minute = defaults.object(forKey: SettingsKey.worryMinute) as? Int ?? WorryTime.defaultMinute
        let exit = WorryTime.next(hour: hour, minute: minute)
        let spot = Worry.nextFreeSpot(occupied: parked.map(\.spotNumber))

        let new = Worry(text: text, spotNumber: spot, intensityBefore: 3, exitAt: exit)
        context.insert(new)
        try context.save()
        await NotificationManager.scheduleExit(ticketID: new.ticketID, spot: spot, at: exit)

        return .result(dialog: IntentDialog(LocalizedStringResource("Parked in spot \(spot). It’ll come back \(WorryTime.describe(exit)).", comment: "Siri: worry parked. Arguments: spot number, when it comes back")))
    }

    /// 앱의 화면과 같은 기준 (→ StoreManager.isPro). 아직 살 수 있는 Pro 상품이 없으면 막지 않는다.
    @MainActor private static func isPro() async -> Bool {
        await StoreManager.shared.currentlyUnlocked()
    }
}

struct WorryParkingShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ParkWorryIntent(),
            phrases: [
                "Park a worry in \(.applicationName)",
                "Park a worry with \(.applicationName)"
            ],
            shortTitle: "Park a Worry",
            systemImageName: "parkingsign"
        )
    }
}
