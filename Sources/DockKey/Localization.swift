import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english
    case simplifiedChinese

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system:
            return L10n.tr("language.system")
        case .english:
            return L10n.tr("language.english")
        case .simplifiedChinese:
            return L10n.tr("language.simplifiedChinese")
        }
    }

    var localizationIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .english:
            return "en"
        case .simplifiedChinese:
            return "zh-Hans"
        }
    }

    var locale: Locale {
        switch self {
        case .system:
            return .current
        case .english:
            return Locale(identifier: "en")
        case .simplifiedChinese:
            return Locale(identifier: "zh-Hans")
        }
    }

    static var current: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: defaultsKey)
        return rawValue.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey)
    }

    private static let defaultsKey = "AppLanguage"
}

enum L10n {
    static func tr(_ key: String, _ arguments: CVarArg...) -> String {
        let format = localizedString(for: key)

        guard !arguments.isEmpty else {
            return format
        }

        return String(format: format, locale: AppLanguage.current.locale, arguments: arguments)
    }

    private static func localizedString(for key: String) -> String {
        if
            let identifier = AppLanguage.current.localizationIdentifier,
            let value = localizedString(for: key, languageIdentifier: identifier)
        {
            return value
        }

        let mainValue = Bundle.main.localizedString(forKey: key, value: nil, table: nil)

        if mainValue != key {
            return mainValue
        }

        if
            let resourceBundle = developmentResourceBundle,
            resourceBundle != Bundle.main
        {
            let resourceValue = resourceBundle.localizedString(forKey: key, value: nil, table: nil)

            if resourceValue != key {
                return resourceValue
            }
        }

        return key
    }

    private static func localizedString(for key: String, languageIdentifier: String) -> String? {
        for bundle in candidateBundles {
            guard
                let path = bundle.path(forResource: languageIdentifier, ofType: "lproj"),
                let languageBundle = Bundle(path: path)
            else {
                continue
            }

            let value = languageBundle.localizedString(forKey: key, value: nil, table: nil)

            if value != key {
                return value
            }
        }

        return nil
    }

    private static var candidateBundles: [Bundle] {
        var bundles = [Bundle.main]

        if
            let resourceBundle = developmentResourceBundle,
            resourceBundle != Bundle.main
        {
            bundles.append(resourceBundle)
        }

        return bundles
    }

    private static var developmentResourceBundle: Bundle? {
        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let bundleURL = executableURL
            .deletingLastPathComponent()
            .appendingPathComponent("DockKey_DockKey.bundle")

        return Bundle(url: bundleURL)
    }
}
