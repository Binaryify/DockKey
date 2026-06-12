import Foundation

final class LaunchAtLoginManager {
    var isEnabled: Bool {
        FileManager.default.fileExists(atPath: launchAgentURL.path)
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try installLaunchAgent()
        } else {
            try removeLaunchAgent()
        }
    }

    private func installLaunchAgent() throws {
        try FileManager.default.createDirectory(
            at: launchAgentURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let plist = makeLaunchAgentPlist()
        let data = try PropertyListSerialization.data(
            fromPropertyList: plist,
            format: .xml,
            options: 0
        )

        try data.write(to: launchAgentURL, options: .atomic)
    }

    private func removeLaunchAgent() throws {
        guard isEnabled else {
            return
        }

        try FileManager.default.removeItem(at: launchAgentURL)
    }

    private func makeLaunchAgentPlist() -> [String: Any] {
        [
            "Label": Self.launchAgentLabel,
            "ProgramArguments": launchArguments(),
            "RunAtLoad": true,
            "LimitLoadToSessionType": "Aqua"
        ]
    }

    private func launchArguments() -> [String] {
        let bundleURL = Bundle.main.bundleURL

        if bundleURL.pathExtension == "app" {
            return ["/usr/bin/open", "-gj", bundleURL.path]
        }

        return [Bundle.main.executableURL?.path ?? CommandLine.arguments[0]]
    }

    private var launchAgentURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library")
            .appendingPathComponent("LaunchAgents")
            .appendingPathComponent("\(Self.launchAgentLabel).plist")
    }

    private static let launchAgentLabel = "dev.binaryify.dockkey.loginitem"
}
