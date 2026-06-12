import AppKit
import Combine
import Foundation

final class AppModel: ObservableObject {
    @Published private(set) var dockApps: [DockApp] = []
    @Published private(set) var hotKeyStatus = "正在启用快捷键..."
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

    var onDockAppsChanged: (() -> Void)?
    var onShortcutsChanged: (() -> Void)?
    var onStatusItemVisibilityChanged: (() -> Void)?
    var onDockIconVisibilityChanged: (() -> Void)?

    private let dockAppReader = DockAppReader()
    private let appLauncher = AppLauncher()
    private let launchAtLoginManager = LaunchAtLoginManager()
    private let updateManager = AppUpdateManager()
    private let hotKeyManager = HotKeyManager()
    private var dockSignature = ""
    private var refreshTimer: Timer?

    init() {
        let savedModifier = UserDefaults.standard.string(forKey: Self.modifierDefaultsKey)
        modifier = savedModifier.flatMap(HotKeyModifier.init(rawValue:)) ?? .command
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
            launchAtLoginMessage = enabled ? "已设置登录后自动启动" : ""
        } catch {
            launchAtLoginEnabled = launchAtLoginManager.isEnabled
            launchAtLoginMessage = "开机启动设置失败: \(error.localizedDescription)"
        }
    }

    func checkForUpdates() {
        guard !isCheckingForUpdates else {
            return
        }

        isCheckingForUpdates = true
        updateStatus = "正在检查更新..."

        Task {
            do {
                guard let update = try await updateManager.latestUpdate() else {
                    await MainActor.run {
                        self.updateStatus = "已是最新版本"
                        self.isCheckingForUpdates = false
                    }
                    return
                }

                await MainActor.run {
                    self.updateStatus = "发现 \(update.tagName)，正在下载..."
                }

                let downloadedURL = try await updateManager.download(update)

                await MainActor.run {
                    self.updateStatus = "已下载 \(update.tagName)，正在打开安装包"
                    self.isCheckingForUpdates = false
                    NSWorkspace.shared.open(downloadedURL)
                }
            } catch {
                await MainActor.run {
                    self.updateStatus = "更新失败: \(error.localizedDescription)"
                    self.isCheckingForUpdates = false
                }
            }
        }
    }

    private func registerHotKeys() {
        let statuses = hotKeyManager.registerShortcuts(modifier: modifier)
        let failures = statuses.enumerated().filter { _, status in status != noErr }

        if failures.isEmpty {
            hotKeyStatus = "快捷键已启用"
            onShortcutsChanged?()
            return
        }

        let failedKeys = failures
            .map { index, status in "\(ShortcutKey.allCases[index].label)(\(status))" }
            .joined(separator: ", ")

        hotKeyStatus = "部分快捷键被占用: \(failedKeys)"
        onShortcutsChanged?()
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
