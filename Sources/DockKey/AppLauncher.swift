import AppKit

final class AppLauncher {
    func toggle(_ app: DockApp) {
        if let runningApplication = runningApplication(for: app) {
            if isFrontmost(runningApplication, matching: app) {
                runningApplication.hide()
                return
            }

            show(runningApplication)
            return
        }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(at: app.url, configuration: configuration) { runningApplication, _ in
            guard let runningApplication else {
                return
            }

            self.show(runningApplication)
        }
    }

    private func runningApplication(for app: DockApp) -> NSRunningApplication? {
        if let bundleIdentifier = app.bundleIdentifier {
            return NSRunningApplication
                .runningApplications(withBundleIdentifier: bundleIdentifier)
                .first
        }

        return NSWorkspace.shared.runningApplications.first { runningApplication in
            runningApplication.bundleURL?.standardizedFileURL == app.url.standardizedFileURL
        }
    }

    private func isFrontmost(_ runningApplication: NSRunningApplication, matching app: DockApp) -> Bool {
        if runningApplication.isActive {
            return true
        }

        guard let frontmostApplication = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        if frontmostApplication.processIdentifier == runningApplication.processIdentifier {
            return true
        }

        guard let bundleIdentifier = app.bundleIdentifier else {
            return false
        }

        return frontmostApplication.bundleIdentifier == bundleIdentifier
    }

    private func show(_ runningApplication: NSRunningApplication) {
        runningApplication.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
    }
}
