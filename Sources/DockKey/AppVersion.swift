import Foundation

struct AppVersion {
    let version: String
    let build: String

    var displayText: String {
        "版本 \(version) (\(build))"
    }

    var copyText: String {
        "\(AppInfo.name) \(version) (\(build))"
    }

    static let current: AppVersion = {
        let infoDictionary = Bundle.main.infoDictionary
        let version = infoDictionary?["CFBundleShortVersionString"] as? String
        let build = infoDictionary?["CFBundleVersion"] as? String

        return AppVersion(
            version: nonEmpty(version) ?? "开发版",
            build: nonEmpty(build) ?? "-"
        )
    }()

    private static func nonEmpty(_ value: String?) -> String? {
        guard let value, !value.isEmpty else {
            return nil
        }

        return value
    }
}
