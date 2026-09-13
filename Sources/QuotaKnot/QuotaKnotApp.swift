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
            QuotaPanelView(model: model)
        } label: {
            Text(model.menuBarText)
                .monospacedDigit()
        }
        .menuBarExtraStyle(.window)
    }
}
