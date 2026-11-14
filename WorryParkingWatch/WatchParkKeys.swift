//
//  WatchParkKeys.swift
//  아이폰 ↔ 애플워치가 함께 쓰는 말. 아이폰 앱에도 같은 파일이 들어간다.
//  워치는 걱정 글을 보내기만 하고 갖고 있지 않는다 — 주차 · 숨김 · 출차 알림은 아이폰이 한다.
//

enum WatchParkKeys {
    /// 워치 → 아이폰: 주차할 걱정 글
    static let park = "park"
    /// 아이폰 → 워치(답): 사람에게 보여 줄 한 줄 ("3번 자리에 주차했어요. 내일 오후 8:00에 돌아와요.")
    static let said = "said"
}
