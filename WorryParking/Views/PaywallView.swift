import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    var body: some View {
        SubscriptionStoreView(productIDs: StoreManager.productIDs) {
            VStack(spacing: 20) {
                ParkingSign(size: 72)
                VStack(spacing: 6) {
                    Text("Worry Parking Pro")
                        .font(.largeTitle.weight(.bold))
                    Text("A bigger lot for a busier mind.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 14) {
                    FeatureRow(
                        systemImage: "square.grid.2x2.fill",
                        title: "Unlimited parking spots",
                        detail: "Park every worry, not just three."
                    )
                    FeatureRow(
                        systemImage: "clock.badge.checkmark",
                        title: "Custom exit times",
                        detail: "Bring a worry back exactly when you can handle it."
                    )
                    FeatureRow(
                        systemImage: "chart.bar.xaxis",
                        title: "Exit insights",
                        detail: "See how many of your fears actually came true."
                    )
                }
            }
            .padding(24)
            .foregroundStyle(.white)
        }
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .cancellation)
        .subscriptionStorePolicyDestination(url: AppConfig.termsURL, for: .termsOfService)
        .subscriptionStorePolicyDestination(url: AppConfig.privacyURL, for: .privacyPolicy)
        .containerBackground(Theme.asphalt.gradient, for: .subscriptionStore)
        .onInAppPurchaseCompletion { _, result in
            if case .success(.success(let verification)) = result,
               case .verified(let transaction) = verification {
                await transaction.finish()
                await store.refreshEntitlements()
                dismiss()
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.white)
            }
            .padding(16)
            .accessibilityLabel("Close")
        }
        .preferredColorScheme(.dark)
    }
}

private struct FeatureRow: View {
    let systemImage: String
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Theme.lineYellow)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
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
