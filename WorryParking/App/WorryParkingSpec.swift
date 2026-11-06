import Foundation
import LeeoKit

/// 앱의 계약. Pro 는 LeeoKit `LeeoStore` 가 맡고(→ StoreManager.swift), 팁은 따로 둔다.
/// ⚠️ 여기서 bootstrap · 피드백 · 분석을 켜지 않는다 — 계약을 채우는 값일 뿐 아무것도 돌지 않는다.
enum WorryParkingSpec: LeeoAppSpec {
    static let appName = "걱정주차장"
    static let developerEmail = "leeo@kakao.com"
    static let feedback = LeeoFeedbackConfig(
        containerIdentifier: "iCloud.com.Ysoup.FeedbackHub",
        appIdentifier: "com.devkoan.worryparking"
    )
    static let legal = LeeoLegalConfig(
        privacyURL: AppConfig.privacyURL,
        supportURL: URL(string: "https://m1zz.github.io/WorryParking/en/support.html")!
    )
    /// 무료 · Pro 두 칸. 걱정을 세워 두고 걱정 시간에 돌려받는 것은 전부 무료,
    /// 칸 무제한 · 출차 시간 지정 · 출차 인사이트만 Pro. 주 · 월 · 연 구독과 평생, 구독자에게만 보이는 졸업 평생가.
    /// 잠그는 자리는 `StoreManager.isPro` 하나만 본다 — 아래 게이트는 그 자리를 적어 둔 계약이다.
    static let monetization = LeeoMonetization.freemiumSubscription(
        LeeoSubscriptionConfig(
            productIDs: ProProduct.all,
            // 자체 약관이 없으므로 애플 표준 사용권 계약(EULA)을 건다. 구독을 파는 앱의 심사 필수 항목이다.
            termsURL: AppConfig.termsURL,
            gate: LeeoGatePolicy(
                freeLimits: [ProFeature.spots.rawValue: AppConfig.freeSpotLimit],
                proOnly: [ProFeature.customExit.rawValue, ProFeature.insights.rawValue])))
    /// 이미 다 가진 사람이 조금 더 내고 싶을 때 내는 곳. 소모성 상품 셋, 작은 것부터.
    /// ⚠️ 기능을 여는 상품이 아니다 — `ProProduct.all` 에 넣지 않는다.
    @MainActor static let tipJar = LeeoTipJar(config: LeeoTipJarConfig(productIDs: [
        "com.devkoan.worryparking.tip.small",
        "com.devkoan.worryparking.tip.medium",
        "com.devkoan.worryparking.tip.large",
    ]))
}

/// 팁을 부탁할 만한 순간 — 출차까지 마친 걱정 수. 출차 게이트에서 하나 돌아볼 때마다 는다.
enum WorryParkingTipMoments {
    /// 출차한 걱정 수. 큰 것부터.
    static let exited = [50, 20, 7]

    /// 넘어선 순간, 인상적인 것부터.
    static func reached(exitedCount count: Int) -> [LeeoTipMoment] {
        exited.filter { count >= $0 }.map { threshold in
            LeeoTipMoment(id: "exited.\(threshold)",
                          message: String(localized: "\(count) worries have left the lot so far",
                                          comment: "Tip ask card: how many worries the person has reviewed and driven out of the lot"))
        }
    }
}
