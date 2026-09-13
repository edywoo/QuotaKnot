import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}

@main
struct QuotaKnotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var model = UsageViewModel()

    var body: some Scene {
        MenuBarExtra {
            Text("코덱스 사용 한도")
                .font(.headline)

            Divider()

            Text("5시간: \(model.fiveHourDetail)")
            Text("주간: \(model.weeklyDetail)")
            Text(model.lastUpdatedText)
            Text("자동 갱신: 질문 전송 · 응답 완료 · 1분마다")

            if let errorMessage = model.errorMessage {
                Divider()
                Text(errorMessage)
            }

            Divider()

            Button(model.isRefreshing ? "새로고침 중…" : "지금 새로고침") {
                Task { await model.refresh() }
            }
            .disabled(model.isRefreshing)

            Button("코덱스 열기") {
                model.openCodex()
            }

            Divider()

            Button("종료") {
                model.quit()
            }
            .keyboardShortcut("q")
        } label: {
            Text(model.menuBarText)
        }
        .menuBarExtraStyle(.menu)
    }
}
