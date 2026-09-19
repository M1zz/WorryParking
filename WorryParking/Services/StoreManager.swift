import Foundation
import Observation
import StoreKit

/// Tracks the Worry Parking Pro subscription ($3.99 / month) with StoreKit 2.
@MainActor
@Observable
final class StoreManager {
    static let proMonthlyID = "com.devkoan.worryparking.pro.monthly"
    static let productIDs = [proMonthlyID]

    private(set) var isPro = false

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    func start() async {
        if updatesTask == nil {
            updatesTask = Task { [weak self] in
                for await update in Transaction.updates {
                    if case .verified(let transaction) = update {
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
