import AppKit
import Combine
import Foundation

final class AppModel: ObservableObject {
    @Published private(set) var dockApps: [DockApp] = []
    @Published private(set) var hotKeyStatus = L10n.tr("hotkeys.enabling")
    @Published private(set) var launchAtLoginMessage = ""
    @Published private(set) var launchAtLoginEnabled: Bool
    @Published private(set) var updateStatus = ""
    @Published private(set) var isCheckingForUpdates = false
    @Published var showsStatusItem: Bool {
        didSet {
            UserDefaults.standard.set(showsStatusItem, forKey: Self.showsStatusItemDefaultsKey)
            onStatusItemVisibilityChanged?()
        }
    }
    @Published var showsDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(showsDockIcon, forKey: Self.showsDockIconDefaultsKey)
            onDockIconVisibilityChanged?()
        }
    }
    @Published var modifier: HotKeyModifier {
        didSet {
            UserDefaults.standard.set(modifier.rawValue, forKey: Self.modifierDefaultsKey)
            registerHotKeys()
        }
    }
    @Published var appLanguage: AppLanguage {
        didSet {
            appLanguage.save()
            refreshLocalizedText()
            onLanguageChanged?()
        }
    }

    var onDockAppsChanged: (() -> Void)?
    var onShortcutsChanged: (() -> Void)?
    var onStatusItemVisibilityChanged: (() -> Void)?
    var onDockIconVisibilityChanged: (() -> Void)?
    var onLanguageChanged: (() -> Void)?

    private let dockAppReader = DockAppReader()
    private let appLauncher = AppLauncher()
    private let launchAtLoginManager = LaunchAtLoginManager()
    private let updateManager = AppUpdateManager()
    private let hotKeyManager = HotKeyManager()
    private var dockSignature = ""
    private var refreshTimer: Timer?
    private var hotKeyFailureSummary: String?
    private var launchAtLoginMessageKey: String?
    private var launchAtLoginMessageArgument: String?
    private var updateStatusKey: String?
    private var updateStatusArgument: String?

    init() {
        let savedModifier = UserDefaults.standard.string(forKey: Self.modifierDefaultsKey)
        modifier = savedModifier.flatMap(HotKeyModifier.init(rawValue:)) ?? .command
        appLanguage = AppLanguage.current
        launchAtLoginEnabled = launchAtLoginManager.isEnabled
        showsStatusItem = UserDefaults.standard.object(forKey: Self.showsStatusItemDefaultsKey) as? Bool ?? true
        showsDockIcon = UserDefaults.standard.object(forKey: Self.showsDockIconDefaultsKey) as? Bool ?? false
    }

    func start() {
        hotKeyManager.start { [weak self] slot in
            DispatchQueue.main.async {
                self?.activateShortcut(slot: slot)
            }
        }

        refreshDockApps(force: true)
        registerHotKeys()
        startRefreshTimer()
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    func refreshDockApps(force: Bool = false) {
        let apps = dockAppReader.readDockApps()
        let nextSignature = apps.map(\.id).joined(separator: "|")

        guard force || nextSignature != dockSignature else {
            return
        }

        dockSignature = nextSignature
        dockApps = apps
        onDockAppsChanged?()
    }

    func app(for shortcutKey: ShortcutKey) -> DockApp? {
        let index = shortcutKey.slot - 1

        guard dockApps.indices.contains(index) else {
            return nil
        }

        return dockApps[index]
    }

    func shortcutLabel(for shortcutKey: ShortcutKey) -> String {
        "\(modifier.symbol)\(shortcutKey.label)"
    }

    func activateShortcut(slot: Int) {
        guard
            slot > 0,
            dockApps.indices.contains(slot - 1)
        else {
            return
        }

        appLauncher.toggle(dockApps[slot - 1])
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try launchAtLoginManager.setEnabled(enabled)
            launchAtLoginEnabled = enabled
            setLaunchAtLoginMessage(enabled ? "launchAtLogin.enabled" : nil)
        } catch {
            launchAtLoginEnabled = launchAtLoginManager.isEnabled
            setLaunchAtLoginMessage("launchAtLogin.failed", argument: error.localizedDescription)
        }
    }

    func checkForUpdates() {
        guard !isCheckingForUpdates else {
            return
        }

        isCheckingForUpdates = true
        setUpdateStatus("update.checking")

        Task {
            do {
                guard let update = try await updateManager.latestUpdate() else {
                    await MainActor.run {
                        self.setUpdateStatus("update.latest")
                        self.isCheckingForUpdates = false
                    }
                    return
                }

                await MainActor.run {
                    self.setUpdateStatus("update.foundDownloading", argument: update.tagName)
                }

                let downloadedURL = try await updateManager.download(update)

                await MainActor.run {
                    self.setUpdateStatus("update.downloadedOpening", argument: update.tagName)
                    self.isCheckingForUpdates = false
                    NSWorkspace.shared.open(downloadedURL)
                }
            } catch {
                await MainActor.run {
                    self.setUpdateStatus("update.failed", argument: error.localizedDescription)
                    self.isCheckingForUpdates = false
                }
            }
        }
    }

    private func registerHotKeys() {
        let statuses = hotKeyManager.registerShortcuts(modifier: modifier)
        let failures = statuses.enumerated().filter { _, status in status != noErr }

        if failures.isEmpty {
            hotKeyFailureSummary = nil
            refreshHotKeyStatus()
            onShortcutsChanged?()
            return
        }

        hotKeyFailureSummary = failures
            .map { index, status in "\(ShortcutKey.allCases[index].label)(\(status))" }
            .joined(separator: ", ")

        refreshHotKeyStatus()
        onShortcutsChanged?()
    }

    private func refreshLocalizedText() {
        refreshHotKeyStatus()
        refreshLaunchAtLoginMessage()
        refreshUpdateStatus()
    }

    private func refreshHotKeyStatus() {
        if let hotKeyFailureSummary {
            hotKeyStatus = L10n.tr("hotkeys.partialFailures", hotKeyFailureSummary)
            return
        }

        hotKeyStatus = L10n.tr("hotkeys.enabled")
    }

    private func setLaunchAtLoginMessage(_ key: String?, argument: String? = nil) {
        launchAtLoginMessageKey = key
        launchAtLoginMessageArgument = argument
        refreshLaunchAtLoginMessage()
    }

    private func refreshLaunchAtLoginMessage() {
        launchAtLoginMessage = localizedStatus(key: launchAtLoginMessageKey, argument: launchAtLoginMessageArgument)
    }

    private func setUpdateStatus(_ key: String?, argument: String? = nil) {
        updateStatusKey = key
        updateStatusArgument = argument
        refreshUpdateStatus()
    }

    private func refreshUpdateStatus() {
        updateStatus = localizedStatus(key: updateStatusKey, argument: updateStatusArgument)
    }

    private func localizedStatus(key: String?, argument: String?) -> String {
        guard let key else {
            return ""
        }

        if let argument {
            return L10n.tr(key, argument)
        }

        return L10n.tr(key)
    }

    private func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.refreshDockApps()
        }
    }

    private static let modifierDefaultsKey = "HotKeyModifier"
    private static let showsStatusItemDefaultsKey = "ShowsStatusItem"
    private static let showsDockIconDefaultsKey = "ShowsDockIcon"
}
