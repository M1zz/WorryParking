//
//  PaywallView.swift
//  WorryParking
//
//  걱정 주차장 Pro 를 파는 한 장, 구독 졸업 시트, 그리고 설정의 Pro 줄.
//
//  **무료인 것을 먼저 말한다.** 비교표의 가운데 세 줄은 무료 · Pro 모두 ✓ 다. 이 화면은
//  "안 사면 못 쓴다"가 아니라 "걱정을 세워 두고 돌려받는 건 전부 무료이고, 칸이 더 필요한 날만 값을 받는다"는 말이다.
//
//  고르는 길: 연 구독(기본) · 평생, 펼치면 주 · 월. 첫 해 할인(App Store 첫 구독 할인)과
//  "연 구독 N년치" 한 줄은 `LeeoTermPicker` 가 알아서 보인다.
//  스토어에서 불러온 상품만 단추가 된다 — 아직 없는 상품은 서지 않는다.
//

import SwiftUI
import StoreKit
import LeeoKit

struct PaywallView: View {
    /// 어디서 막혀 들어왔는가. 그 줄을 비교표에서 강조한다.
    var highlight: ProFeature?

    @Environment(StoreManager.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    /// 결제 시트를 **이 페이월이 떠 있는 창**에 띄운다.
    @Environment(\.purchase) private var purchaseAction

    @State private var term: LeeoPlanTerm = .yearly
    /// 펼쳐서 고른 주 · 월 구독. 고르면 연 / 평생 대신 이것을 산다.
    @State private var shortPlanID: String?
    @State private var loadingProducts = true

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    comparison
                    if store.hasPro {
                        Label("You have Worry Parking Pro. Thank you.", systemImage: "checkmark.seal.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.readyGreen)
                    } else {
                        plans
                    }
                    if let message = store.failureMessage, !store.products.isEmpty {
                        Label(message, systemImage: "exclamationmark.triangle")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    legal
                }
                .padding(24)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.asphalt.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.asphalt, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { dismiss() } label: { Label("Not now", systemImage: "xmark") }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Restore purchases") {
                        Task {
                            await store.restore()
                            if store.hasPro { dismiss() }
                        }
                    }
                    .disabled(store.isWorking)
                }
            }
            .task { await loadPlans() }
        }
        .leeoStyle(.worryParking)
        .preferredColorScheme(.dark)
    }

    // MARK: 머리

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            ParkingSign(size: 56)
                .accessibilityHidden(true)
            Text("Worry Parking Pro")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
            Text("A bigger lot for busy-mind days. Go yearly or lifetime.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if highlight == .spots, !store.isPro {
                Label("All \(AppConfig.freeSpotLimit) free spots are taken.", systemImage: "parkingsign")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.lineYellow)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: 비교표

    private var comparison: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                Text("Feature")
                Text("Free").gridColumnAlignment(.center)
                Text(verbatim: "Pro").gridColumnAlignment(.center)
            }
            .font(.body.weight(.semibold))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)
            Divider().gridCellColumns(3)
            row("Parking spots", free: String(localized: "\(AppConfig.freeSpotLimit) spots"),
                pro: String(localized: "Unlimited"), feature: .spots)
            row("Exits at Worry Time")
            row("Worry Time reminders · exit gate")
            row("Exit Log")
            row("Custom exit times", feature: .customExit)
            row("Exit insights", feature: .insights)
        }
        .padding(16)
        .background(Theme.asphaltLight, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// 한 줄. `free` · `pro` 가 nil 이면 ✓, `feature` 가 있고 `free` 가 nil 이면 무료 칸은 – 다.
    private func row(_ title: LocalizedStringKey, free: String? = nil, pro: String? = nil,
                     feature: ProFeature? = nil) -> some View {
        let isHighlighted = feature != nil && feature == highlight
        let freeIncluded = feature == nil || free != nil
        return GridRow {
            Text(title).fixedSize(horizontal: false, vertical: true)
            cell(free, included: freeIncluded)
            cell(pro, included: true)
        }
        .font(.body.weight(isHighlighted ? .semibold : .regular))
        .foregroundStyle(isHighlighted ? Theme.lineYellow : .primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(title))
        .accessibilityValue(accessibilityValue(free: free, freeIncluded: freeIncluded, pro: pro))
    }

    @ViewBuilder
    private func cell(_ text: String?, included: Bool) -> some View {
        Group {
            if let text {
                Text(text).multilineTextAlignment(.center)
            } else if included {
                Image(systemName: "checkmark")
                    .font(.body.weight(.bold))
                    .foregroundStyle(Theme.lineYellow)
            } else {
                Text(verbatim: "–").foregroundStyle(.secondary)
            }
        }
        .frame(minWidth: 56)
    }

    private func accessibilityValue(free: String?, freeIncluded: Bool, pro: String?) -> String {
        if let free, let pro {
            return String(localized: "Free: \(free). Pro: \(pro).")
        }
        return freeIncluded ? String(localized: "Included for free") : String(localized: "Pro only")
    }

    // MARK: 요금제

    @ViewBuilder
    private var plans: some View {
        let yearly = store.product(ProProduct.yearly)
        let lifetime = store.product(ProProduct.lifetime)
        if yearly == nil && lifetime == nil {
            plansStatus
        } else {
            VStack(alignment: .leading, spacing: 14) {
                LeeoTermPicker(term: Binding(get: { term }, set: { term = $0; shortPlanID = nil }),
                               yearly: yearly, lifetime: lifetime)
                    .opacity(shortPlanID == nil ? 1 : 0.5)
                shortPlans
                buyButton
            }
        }
    }

    /// 주 · 월 구독. 연 구독이 기본이라 펼쳐야 보인다. 불러온 상품만 줄이 선다.
    @ViewBuilder
    private var shortPlans: some View {
        let short = [store.product(ProProduct.monthly), store.product(ProProduct.weekly)].compactMap { $0 }
        if !short.isEmpty {
            DisclosureGroup("See weekly and monthly plans") {
                VStack(spacing: 4) {
                    ForEach(short, id: \.id) { shortPlanRow($0) }
                }
                .padding(.top, 6)
            }
            .font(.body)
        }
    }

    private func shortPlanRow(_ product: Product) -> some View {
        let selected = shortPlanID == product.id
        let title = product.id == ProProduct.weekly
            ? String(localized: "Weekly · \(product.displayPrice) / week", comment: "Paywall: weekly plan row. %@ = price")
            : String(localized: "Monthly · \(product.displayPrice) / month", comment: "Paywall: monthly plan row. %@ = price")
        return Button {
            shortPlanID = selected ? nil : product.id
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(selected ? Theme.lineYellow : .secondary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    /// 지금 고른 상품.
    private var chosen: Product? {
        if let shortPlanID { return store.product(shortPlanID) }
        return store.product(term == .yearly ? ProProduct.yearly : ProProduct.lifetime)
    }

    private var buyTitle: String {
        switch shortPlanID {
        case ProProduct.weekly?:  String(localized: "Start weekly plan")
        case ProProduct.monthly?: String(localized: "Start monthly plan")
        default: term == .yearly ? String(localized: "Start yearly plan") : String(localized: "Buy lifetime")
        }
    }

    private var buyButton: some View {
        Button {
            guard let chosen else { return }
            Task {
                await store.purchase(chosen, using: purchaseAction)
                if store.hasPro { dismiss() }
            }
        } label: {
            Group {
                if store.isWorking {
                    ProgressView().tint(Theme.ink)
                } else {
                    Text(buyTitle)
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(store.isWorking || chosen == nil)
    }

    @ViewBuilder
    private var plansStatus: some View {
        if loadingProducts {
            HStack(spacing: 10) {
                ProgressView()
                Text("Loading plans…").font(.body).foregroundStyle(.secondary)
            }
        } else {
            // 한 번 실패하면 죽은 단추로 남지 않게, 그 자리에서 다시 청한다.
            VStack(alignment: .leading, spacing: 10) {
                Text("Couldn't load plans. Check your internet connection and try again.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    Task { await loadPlans() }
                } label: {
                    Label("Try again", systemImage: "arrow.clockwise").font(.body.weight(.semibold))
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    /// 첫 조회가 비어 오면 한 번 더 청한다. 샌드박스(심사 환경)는 첫 조회가 빈손으로 오는 일이 잦다.
    private func loadPlans() async {
        loadingProducts = true
        await store.loadProducts()
        if store.products.isEmpty {
            try? await Task.sleep(for: .seconds(1.5))
            await store.loadProducts()
        }
        loadingProducts = false
    }

    // MARK: 약관 (구독을 파는 앱의 심사 필수 항목)

    private var legal: some View {
        VStack(alignment: .leading, spacing: 10) {
            if store.products.contains(where: { $0.subscription != nil }) {
                Text("Subscriptions renew automatically at the same price unless cancelled at least 24 hours before the period ends, and are charged to your Apple Account. If you start the yearly plan for the first time, your first year is charged at the discounted price and renews at the regular price after that. Manage or cancel anytime in your App Store account settings. Lifetime is a one-time purchase, not a subscription.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            HStack(spacing: 20) {
                Link("Terms of Use", destination: AppConfig.termsURL)
                Link("Privacy Policy", destination: AppConfig.privacyURL)
            }
            .font(.body)
        }
    }
}

// MARK: - 구독 졸업

/// 구독 중인 사람에게 평생으로 옮겨 갈 값을 보인다. 사면 구독 관리 화면으로 해지를 돕는다.
struct ProGraduationSheet: View {
    @Environment(StoreManager.self) private var store

    var body: some View {
        LeeoGraduationOfferView(graduate: store.product(ProProduct.graduate)) {
            await store.refresh()
        }
        .task { if store.product(ProProduct.graduate) == nil { await store.loadProducts() } }
        // 졸업 단추는 흰 글자다 — 노란 바탕에서는 읽히지 않아 파란 표지판 색을 쓴다.
        .leeoStyle(LeeoStyle(accent: Theme.signBlue, bg: Theme.asphalt,
                             surface: Theme.asphaltLight, surfaceAlt: Theme.asphaltLight))
        .preferredColorScheme(.dark)
    }
}

// MARK: - 설정의 Pro 줄

/// 설정 ▸ 걱정 주차장 Pro. 무료면 페이월로, 구독 중이면 구독 관리와 '평생으로 바꾸기', 복원은 늘.
struct ProSettingsSection: View {
    @Environment(StoreManager.self) private var store
    @State private var showingPaywall = false
    @State private var showingGraduation = false
    @State private var showingManage = false
    @State private var restoreMessage: String?

    var body: some View {
        Section {
            if !store.hasPro {
                // 아직 살 수 있는 상품이 없으면 줄을 세우지 않는다 — 누르면 '불러오지 못했다' 만 보인다.
                if store.sellsPro {
                    Button { showingPaywall = true } label: {
                        Label("Unlimited spots, custom exit times, insights", systemImage: "sparkles")
                    }
                }
            } else if store.ownsLifetime {
                Label("Pro for life", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.readyGreen)
            } else if store.subscription != nil {
                Label("Pro is active", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.readyGreen)
                Button { showingManage = true } label: {
                    Label("Manage subscription", systemImage: "creditcard")
                }
                Button { showingGraduation = true } label: {
                    Label(LeeoLadderText.switchToLifetimeEntry, systemImage: "graduationcap")
                }
            } else {
                // 페이월 전에 설치한 사람 · 가족 공유로 받은 사람.
                Label("Pro is active", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(Theme.readyGreen)
            }
            Button {
                Task {
                    await store.restore()
                    restoreMessage = store.hasPro ? nil : store.failureMessage
                }
            } label: {
                Label("Restore purchases", systemImage: "arrow.clockwise")
            }
            .disabled(store.isWorking)
        } header: {
            Text("Worry Parking Pro")
        } footer: {
            if let restoreMessage { Text(restoreMessage) }
        }
        .sheet(isPresented: $showingPaywall) { PaywallView() }
        .sheet(isPresented: $showingGraduation) { ProGraduationSheet() }
        .manageSubscriptionsSheet(isPresented: $showingManage)
    }
}

extension LeeoStyle {
    /// 아스팔트 바탕에 노란 주차선. LeeoKit 의 연 구독 / 평생 고르기가 앱과 같은 색으로 선다.
    static let worryParking = LeeoStyle(accent: Theme.lineYellow, bg: Theme.asphalt,
                                        surface: Theme.asphaltLight, surfaceAlt: Theme.asphaltLight)
}
