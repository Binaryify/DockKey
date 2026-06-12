import AppKit
import Foundation

final class DockAppReader {
    private let dockPreferencesURL: URL

    init(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        dockPreferencesURL = homeDirectory
            .appendingPathComponent("Library")
            .appendingPathComponent("Preferences")
            .appendingPathComponent("com.apple.dock.plist")
    }

    func readDockApps() -> [DockApp] {
        CFPreferencesAppSynchronize("com.apple.dock" as CFString)

        guard
            let data = try? Data(contentsOf: dockPreferencesURL),
            let plist = try? PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any],
            let items = plist["persistent-apps"] as? [[String: Any]]
        else {
            return []
        }

        return items.compactMap(makeDockApp(from:))
    }

    private func makeDockApp(from item: [String: Any]) -> DockApp? {
        guard
            item["tile-type"] as? String == "file-tile",
            let tileData = item["tile-data"] as? [String: Any],
            let appURL = resolveAppURL(from: tileData),
            appURL.pathExtension == "app"
        else {
            return nil
        }

        let bundle = Bundle(url: appURL)
        let bundleIdentifier = (tileData["bundle-identifier"] as? String) ?? bundle?.bundleIdentifier
        let displayName = displayName(for: appURL, tileData: tileData, bundle: bundle)
        let icon = NSWorkspace.shared.icon(forFile: appURL.path)
        icon.size = NSSize(width: 28, height: 28)

        return DockApp(
            url: appURL,
            name: displayName,
            bundleIdentifier: bundleIdentifier,
            icon: icon
        )
    }

    private func resolveAppURL(from tileData: [String: Any]) -> URL? {
        if
            let fileData = tileData["file-data"] as? [String: Any],
            let rawURL = fileData["_CFURLString"] as? String
        {
            if rawURL.hasPrefix("file://") {
                return URL(string: rawURL)?.standardizedFileURL
            }

            return URL(fileURLWithPath: rawURL).standardizedFileURL
        }

        if
            let bundleIdentifier = tileData["bundle-identifier"] as? String,
            let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        {
            return url.standardizedFileURL
        }

        return nil
    }

    private func displayName(for url: URL, tileData: [String: Any], bundle: Bundle?) -> String {
        if let label = tileData["file-label"] as? String, !label.isEmpty {
            return label
        }

        if let displayName = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return displayName
        }

        if let bundleName = bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return bundleName
        }

        return url.deletingPathExtension().lastPathComponent
    }
}
