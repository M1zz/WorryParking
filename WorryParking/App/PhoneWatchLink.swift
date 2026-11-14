//
//  PhoneWatchLink.swift
//  아이폰 쪽 워치 연결. 손목에서 말한 걱정을 받아 주차한다(Siri '걱정 주차' 와 같은 길 → WorryParker).
//  워치가 짝지어 있지 않으면 아무것도 하지 않는다. visionOS 에는 워치가 없다.
//

#if os(iOS)
import Foundation
import SwiftData
import WatchConnectivity

final class PhoneWatchLink: NSObject, WCSessionDelegate, @unchecked Sendable {
    static let shared = PhoneWatchLink()
    private var container: ModelContainer?

    func activate(_ container: ModelContainer) {
        self.container = container
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private func park(_ info: [String: Any]) async -> String? {
        guard let container, let text = (info[WatchParkKeys.park] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        return try? await WorryParker.park(text, in: container)
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    /// 가까이 있을 때: 주차하고 한 줄로 답한다
    func session(_ session: WCSession, didReceiveMessage message: [String: Any],
                 replyHandler: @escaping ([String: Any]) -> Void) {
        Task {
            let said = await park(message)
            replyHandler(said.map { [WatchParkKeys.said: $0] } ?? [:])
        }
    }

    /// 멀리 있다가 이어졌을 때: 답할 곳이 없으니 주차만 한다(출차 알림이 손목으로도 온다)
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        Task { _ = await park(userInfo) }
    }
}
#endif
