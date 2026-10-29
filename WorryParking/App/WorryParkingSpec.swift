import Foundation
import LeeoKit

/// LeeoKit 은 팁 화면에만 쓴다. 구독은 앱의 `StoreManager` 가 그대로 맡는다.
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
    /// 구독은 LeeoKit 밖(`StoreManager`)에 있다. LeeoKit 이 페이월을 그리지 않게 `.free` 로 둔다.
    static let monetization = LeeoMonetization.free

    /// 이미 다 가진 사람이 조금 더 내고 싶을 때 내는 곳. 소모성 상품 셋, 작은 것부터.
    /// ⚠️ 기능을 여는 상품이 아니다 — `StoreManager.productIDs` 에 넣지 않는다.
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
