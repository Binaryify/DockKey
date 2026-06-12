import Foundation

enum AppInfo {
    static var name: String {
        nonEmpty(Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "DockKey"
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }

        return value
    }
}
