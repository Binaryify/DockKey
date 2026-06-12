import AppKit
import SwiftUI

final class PreferencesWindowController: NSWindowController {
    init(model: AppModel) {
        let hostingController = NSHostingController(rootView: PreferencesView(model: model))
        let window = NSWindow(contentViewController: hostingController)
        window.title = AppInfo.name
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 430))
        window.isReleasedWhenClosed = false

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    func show() {
        guard let window else {
            return
        }

        if !window.isVisible {
            window.center()
        }

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
