import Foundation
import Observation
import StoreKit

/// Tracks the Worry Parking Pro subscription ($3.99 / month) with StoreKit 2.
@MainActor
@Observable
final class StoreManager {
    static let proMonthlyID = "com.devkoan.worryparking.pro.monthly"
    static let productIDs = [proMonthlyID]

    private(set) var isPro = !AppConfig.subscriptionsEnabled

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    func start() async {
        guard AppConfig.subscriptionsEnabled else { return }
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await update in Transaction.updates {
                    // 구독만 여기서 닫는다. 팁은 LeeoTipJar 가 세고 닫는다(기능을 열지 않는다).
                    if case .verified(let transaction) = update, Self.productIDs.contains(transaction.productID) {
                        await transaction.finish()
                    }
                    await self?.refreshEntitlements()
                }
            }
        }
        await refreshEntitlements()
    }

    func refreshEntitlements() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    #if DEBUG
    /// Screenshot mode only: show the Pro experience without a transaction.
    func unlockForScreenshots() {
        isPro = true
    }
    #endif

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }
}
