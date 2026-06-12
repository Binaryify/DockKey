import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let model = AppModel()
    private var statusItem: NSStatusItem?
    private var preferencesWindowController: PreferencesWindowController?
    private var quitEventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.applicationIconImage = AppIconProvider.appIcon(size: NSSize(width: 128, height: 128))
        configureMainMenu()
        configureKeyboardShortcuts()

        model.onDockAppsChanged = { [weak self] in
            self?.rebuildStatusMenu()
        }
        model.onShortcutsChanged = { [weak self] in
            self?.rebuildStatusMenu()
        }
        model.onStatusItemVisibilityChanged = { [weak self] in
            self?.updateStatusItemVisibility()
        }
        model.onDockIconVisibilityChanged = { [weak self] in
            self?.updateDockIconVisibility()
        }

        updateDockIconVisibility()
        updateStatusItemVisibility()
        model.start()
        showPreferencesIfNeeded()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model.stop()

        if let quitEventMonitor {
            NSEvent.removeMonitor(quitEventMonitor)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showPreferences()
        }

        return true
    }

    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController(model: model)
        }

        preferencesWindowController?.show()
    }

    @objc private func refreshDockApps() {
        model.refreshDockApps(force: true)
    }

    @objc private func checkForUpdates() {
        model.checkForUpdates()
        showPreferences()
    }

    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = AppInfo.name
        alert.informativeText = AppVersion.current.displayText
        alert.icon = AppIconProvider.appIcon(size: NSSize(width: 96, height: 96))
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func activateMenuItemApp(_ sender: NSMenuItem) {
        model.activateShortcut(slot: sender.tag)
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()

        appMenu.addItem(NSMenuItem(title: "关于 \(AppInfo.name)", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "退出 \(AppInfo.name)", action: #selector(quit), keyEquivalent: "q"))

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func configureKeyboardShortcuts() {
        guard quitEventMonitor == nil else {
            return
        }

        quitEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            let disallowedFlags: NSEvent.ModifierFlags = [.option, .control, .shift]

            guard
                flags.contains(.command),
                flags.intersection(disallowedFlags).isEmpty,
                event.charactersIgnoringModifiers?.lowercased() == "q"
            else {
                return event
            }

            NSApp.terminate(nil)
            return nil
        }
    }

    private func configureStatusItem() {
        guard statusItem == nil else {
            return
        }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = AppIconProvider.menuBarIcon()
        statusItem.button?.imagePosition = .imageLeading
        self.statusItem = statusItem

        rebuildStatusMenu()
    }

    private func updateStatusItemVisibility() {
        if model.showsStatusItem {
            configureStatusItem()
            return
        }

        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
            self.statusItem = nil
        }
    }

    private func updateDockIconVisibility() {
        let policy: NSApplication.ActivationPolicy = model.showsDockIcon ? .regular : .accessory
        NSApp.setActivationPolicy(policy)
    }

    private func rebuildStatusMenu() {
        guard statusItem != nil else {
            return
        }

        let menu = NSMenu()

        let titleItem = NSMenuItem(title: AppInfo.name, action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "偏好设置...", action: #selector(showPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem(title: "关于 \(AppInfo.name)", action: #selector(showAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "检查更新", action: #selector(checkForUpdates), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "刷新 Dock App", action: #selector(refreshDockApps), keyEquivalent: "r"))

        let visibleShortcutKeys = ShortcutKey.allCases.filter { model.app(for: $0) != nil }

        if !visibleShortcutKeys.isEmpty {
            menu.addItem(NSMenuItem.separator())

            for shortcutKey in visibleShortcutKeys {
                guard let app = model.app(for: shortcutKey) else {
                    continue
                }

                let item = NSMenuItem(
                    title: "\(model.shortcutLabel(for: shortcutKey))  \(app.name)",
                    action: #selector(activateMenuItemApp(_:)),
                    keyEquivalent: ""
                )
                item.image = app.icon
                item.tag = shortcutKey.slot
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出 \(AppInfo.name)", action: #selector(quit), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    private func showPreferencesIfNeeded() {
        let key = "DidShowPreferencesOnFirstLaunch"

        guard !UserDefaults.standard.bool(forKey: key) else {
            return
        }

        UserDefaults.standard.set(true, forKey: key)
        showPreferences()
    }
}
