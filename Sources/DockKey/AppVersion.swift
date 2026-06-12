import Foundation

struct AppVersion {
    let version: String
    let build: String

    var displayText: String {
        L10n.tr("version.display", version)
    }

    static let current: AppVersion = {
        let infoDictionary = Bundle.main.infoDictionary
        let version = infoDictionary?["CFBundleShortVersionString"] as? String
        let build = infoDictionary?["CFBundleVersion"] as? String

        return AppVersion(
            version: nonEmpty(version) ?? L10n.tr("version.development"),
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
