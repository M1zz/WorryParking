//
//  WorryParkingWatchApp.swift
//  손목의 걱정 주차장: 자기 전 걱정이 떠오르면 폰을 들지 않고 손목에 한 번 말하고 내려놓는다.
//  폰 화면의 불빛과 스크롤이 잠을 더 깨운다 — 화면을 켜지 않고 걱정을 미루는 것이 이 앱의 일이다.
//  워치는 걱정 글을 갖고 있지 않다. 아이폰이 주차하고, 걱정 시간에 출차 알림을 보낸다(손목으로도 넘어온다).
//

import SwiftUI
import WatchConnectivity
import WatchKit

@main
struct WorryParkingWatchApp: App {
    var body: some Scene {
        WindowGroup { ParkView() }
    }
}

struct ParkView: View {
    @StateObject private var link = WatchLink()

    var body: some View {
        ScrollView { content }
    }

    private var content: some View {
        VStack(spacing: 10) {
            Image(systemName: "parkingsign.circle.fill")
                .font(.system(size: link.state == .idle ? 44 : 28))
                .foregroundStyle(.tint)
            switch link.state {
            case .idle:
                Text("Say it once and let it go until Worry Time.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            case .sending:
                ProgressView()
            case .done(let said):
                Text(said).font(.footnote).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            // 누르면 받아쓰기 · 손글씨 · 키보드 입력이 뜬다. 끝내면 바로 보낸다.
            TextFieldLink(prompt: Text("What’s on your mind?")) {
                Label("Park a Worry", systemImage: "mic.fill")
            } onSubmit: { text in
                link.park(text)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .task {
            link.activate()
            #if DEBUG
            link.showDemoIfAsked()
            #endif
        }
    }
}

@MainActor
final class WatchLink: NSObject, ObservableObject, WCSessionDelegate {
    enum State: Equatable { case idle, sending, done(String) }
    @Published private(set) var state = State.idle

    func activate() {
        guard WCSession.isSupported(), WCSession.default.activationState != .activated else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// 가까우면 바로 주차하고 아이폰의 답(몇 번 자리 · 언제 돌아오는지)을 보여 준다.
    /// 멀면 이어질 때 주차된다 — 다시 말할 필요가 없다.
    func park(_ text: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        state = .sending
        activate()
        Task { await send([WatchParkKeys.park: text]) }
    }

    private func send(_ message: [String: Any]) async {
        let wc = WCSession.default
        // 막 켠 앱이면 연결이 서기까지 잠깐 기다린다
        for _ in 0..<15 where wc.activationState != .activated {
            try? await Task.sleep(for: .milliseconds(200))
        }
        let later = String(localized: "It’ll be parked when your iPhone is nearby.")
        guard wc.activationState == .activated, wc.isReachable else {
            wc.transferUserInfo(message)
            finish(later)
            return
        }
        wc.sendMessage(message) { reply in
            let said = reply[WatchParkKeys.said] as? String
            Task { @MainActor in self.finish(said ?? later) }
        } errorHandler: { _ in
            wc.transferUserInfo(message)
            Task { @MainActor in self.finish(later) }
        }
    }

    #if DEBUG
    /// 스크린샷: `-watchDemoDone YES` 면 아이폰이 답한 뒤의 모습(몇 번 자리 · 언제 돌아오는지)을 띄운다
    func showDemoIfAsked() {
        guard UserDefaults.standard.bool(forKey: "watchDemoDone") else { return }
        let back = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now.addingTimeInterval(86_400))!
        let time = back.formatted(date: .omitted, time: .shortened)
        state = .done(String(localized: "Parked in spot \(3). It’ll come back \(String(localized: "tomorrow at \(time)")).",
                             comment: "Siri: worry parked. Arguments: spot number, when it comes back"))
    }
    #endif

    private func finish(_ said: String) {
        WKInterfaceDevice.current().play(.success)
        state = .done(said)
    }

    nonisolated func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {}
}
