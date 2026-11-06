import Foundation
import Combine
import Observation
import StoreKit
import SwiftUI
import LeeoKit

// MARK: - 상품

/// App Store Connect · Products.storekit 과의 계약 — 한 번 정하면 바꾸지 않는다.
/// 주 · 월 · 연 구독은 구독 그룹 "Worry Parking Pro" 하나에 둔다.
enum ProProduct {
    private static let base = "com.devkoan.worryparking.pro"
    static let weekly   = base + ".weekly"
    static let monthly  = base + ".monthly"
    static let yearly   = base + ".yearly"
    static let lifetime = base + ".lifetime"
    /// 구독 졸업 — 구독 중인 사람에게만 보이는 평생가.
    static let graduate = base + ".graduate"

    static let subscriptions: Set<String> = [weekly, monthly, yearly]
    static let lifetimes: Set<String> = [lifetime, graduate]

    /// 불러올 순서. 팁 상품은 여기 넣지 않는다 — 팁은 아무것도 열지 않는다.
    static let all: [String] = [yearly, lifetime, monthly, weekly, graduate]
}

/// Pro 가 여는 것. 페이월이 어디서 막혀 들어왔는지 알려 줄 때 쓴다.
enum ProFeature: String, Identifiable {
    /// 주차 칸 무제한 (무료는 `AppConfig.freeSpotLimit` 칸)
    case spots
    /// 출차 시간 직접 지정
    case customExit
    /// 출차 인사이트
    case insights

    var id: String { rawValue }
}

// MARK: - 권한

/// 걱정 주차장 Pro — 무료 · Pro 두 칸. **속은 LeeoKit 의 `LeeoStore` 다.**
///
/// 걱정을 세워 두고 걱정 시간에 돌려받는 것은 끝까지 무료다. 칸 무제한 · 출차 시간 지정 · 출차 인사이트만 Pro.
/// 상품 로드 · 구매 · 복원 · 거래 리스너(다른 기기, 가족 공유, 환불, 만료)는 LeeoStore 안에 있다.
@MainActor
@Observable
final class StoreManager {
    static let shared = StoreManager()

    @ObservationIgnored let store: LeeoStore

    /// 산 것 · 구독 중인 것 · 페이월 전에 설치한 사람.
    private(set) var hasPro = false
    private(set) var products: [Product] = []
    private(set) var ownedProductIDs: Set<String> = []
    /// 지금 살아 있는 구독. 있으면 설정에 '평생으로 바꾸기' 가 선다.
    private(set) var subscription: LeeoGraduation.Subscription?
    private(set) var isWorking = false
    /// 사다가 막혔을 때 화면에 그대로 보여 줄 말.
    private(set) var failureMessage: String?

    /// **이 기기가 스토어에서 Pro 상품을 한 번이라도 불러왔는가.**
    ///
    /// 상품을 App Store Connect 에 만들기 전에 빌드가 나가면 아무도 살 수 없다. 그때 무료 한도로 막으면
    /// 사지도 못하고 막히기만 한다. 그래서 한 번도 못 불러온 기기는 막지 않는다.
    /// 한 번 불러온 기기는 그 뒤 잠깐 네트워크가 끊겨도 다시 막는다(살 수 있는 상품이 있다는 걸 안다).
    private(set) var sellsPro: Bool

    #if DEBUG
    /// 스크린샷 모드만: 거래 없이 Pro 화면을 보인다.
    private var unlockedForScreenshots = false
    func unlockForScreenshots() { unlockedForScreenshots = true }
    #endif

    /// **Pro 기능이 지금 열려 있는가.** 잠그는 자리는 모두 이것만 본다.
    /// Pro 를 가졌거나, 아직 살 수 있는 상품이 없으면 열려 있다.
    var isPro: Bool {
        #if DEBUG
        if unlockedForScreenshots { return true }
        #endif
        return hasPro || !sellsPro
    }

    /// 평생 Pro(평생 · 구독 졸업)를 가졌는가.
    var ownsLifetime: Bool { !ownedProductIDs.isDisjoint(with: ProProduct.lifetimes) }

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var observation: AnyCancellable?
    private static let sellsProKey = "pro.sellsPro"

    private init(defaults: UserDefaults = .standard) {
        guard let config = WorryParkingSpec.paywall else {
            preconditionFailure("계약에 페이월이 없다. WorryParkingSpec.monetization 을 확인할 것")
        }
        self.defaults = defaults
        sellsPro = defaults.bool(forKey: Self.sellsProKey)
        store = LeeoStore(config: config, grandfather: { await StoreManager.installedBeforePaywall() })
        // ⚠️ objectWillChange 는 값이 바뀌기 **직전**에 온다. 다음 차례로 미뤄서 읽는다.
        observation = store.objectWillChange.sink { [weak self] _ in
            Task { @MainActor in self?.pull() }
        }
        pull()
    }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    // MARK: 상태 맞추기

    /// 영수증을 다시 읽고 상품을 불러온다. 앱이 켜질 때와 다시 앞에 올 때마다 부른다.
    func refresh() async {
        await store.refreshEntitlements()
        await store.loadProducts()
        subscription = await LeeoGraduation.currentSubscription(among: ProProduct.subscriptions)
        pull()
    }

    func loadProducts() async {
        await store.loadProducts()
        pull()
    }

    /// 앱을 열지 않고 도는 곳(Siri)에서 묻는다. 영수증을 한 번 읽고 답한다.
    func currentlyUnlocked() async -> Bool {
        await store.refreshEntitlements()
        pull()
        return isPro
    }

    /// **구독 졸업을 제안할 때인가.** 6개월째와 갱신 7일 전에 한 번씩 (→ LeeoGraduation).
    /// 이미 평생을 가졌으면 제안하지 않는다. 띄운 쪽이 `markGraduationOffered()` 를 부른다.
    var graduationIsDue: Bool {
        guard let subscription, !ownsLifetime, product(ProProduct.graduate) != nil else { return false }
        return LeeoGraduation.isDue(subscription, lastOffered: LeeoGraduation.lastOffered())
    }

    func markGraduationOffered() { LeeoGraduation.markOffered() }

    // MARK: 사기 / 되찾기

    /// ⚠️ `action` 은 페이월의 `@Environment(\.purchase)` 다. 결제 시트가 이 창에 뜬다.
    func purchase(_ product: Product, using action: PurchaseAction) async {
        _ = await store.purchase(product) { try await action($0) }
        subscription = await LeeoGraduation.currentSubscription(among: ProProduct.subscriptions)
        pull()
    }

    /// 기기를 바꿨거나 앱을 지웠다 받은 사람이 되찾는 길. 심사에서도 요구한다.
    func restore() async {
        await store.restore()
        subscription = await LeeoGraduation.currentSubscription(among: ProProduct.subscriptions)
        pull()
        if !hasPro, failureMessage == nil {
            failureMessage = String(localized: "No purchases were found for this Apple Account.",
                                    comment: "Restore purchases: nothing found")
        }
    }

    // MARK: -

    private func pull() {
        hasPro = store.hasPro
        products = store.products
        ownedProductIDs = store.purchasedProductIDs
        isWorking = store.purchasingProductID != nil || store.isRestoring
        failureMessage = store.lastError
        // 팔 수 있는 Pro 상품이 하나라도 보였으면 그때부터 무료 한도가 걸린다.
        if !sellsPro, products.contains(where: { ProProduct.all.contains($0.id) }) {
            sellsPro = true
            defaults.set(true, forKey: Self.sellsProKey)
        }
    }

    // MARK: - 페이월 전에 설치한 사람

    /// 페이월이 없던 마지막 빌드(1.0.2 빌드 7). 그때까지는 모든 기능이 무료였다.
    /// 이 빌드까지 받은 사람은 Pro 를 그대로 쓴다 — 쓰던 칸 · 출차 시간 지정 · 인사이트를 뺏지 않는다.
    nonisolated static let lastBuildBeforePaywall = 7

    /// App Store 가 서명한 최초 다운로드 빌드로 알아본다. 지웠다 다시 받아도 같다.
    /// 시험 환경(Xcode · 샌드박스)은 최초 빌드가 엉뚱하게 오므로 출시 영수증만 믿는다.
    static func installedBeforePaywall() async -> Bool {
        guard case .verified(let app)? = try? await AppTransaction.shared,
              app.environment == .production else { return false }
        return isBuildBeforePaywall(app.originalAppVersion)
    }

    /// `originalAppVersion` 은 iOS 에서 CFBundleVersion(빌드 번호)이다.
    nonisolated static func isBuildBeforePaywall(_ originalAppVersion: String) -> Bool {
        guard let build = Int(originalAppVersion.split(separator: ".").first ?? "") else { return false }
        return build <= lastBuildBeforePaywall
    }
}
