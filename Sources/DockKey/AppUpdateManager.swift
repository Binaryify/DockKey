import Foundation

struct AppUpdate {
    let version: String
    let tagName: String
    let releaseURL: URL
    let notes: String
    let assetName: String
    let assetURL: URL
}

final class AppUpdateManager {
    func latestUpdate(currentVersion: String = AppVersion.current.version) async throws -> AppUpdate? {
        let release = try await latestRelease()
        let releaseVersion = Self.normalizedVersion(release.tagName)

        guard Self.compareVersions(releaseVersion, currentVersion) == .orderedDescending else {
            return nil
        }

        guard let asset = release.preferredDownloadAsset else {
            throw UpdateError.noDownloadAsset
        }

        return AppUpdate(
            version: releaseVersion,
            tagName: release.tagName,
            releaseURL: release.htmlURL,
            notes: release.body ?? "",
            assetName: asset.name,
            assetURL: asset.browserDownloadURL
        )
    }

    func download(_ update: AppUpdate) async throws -> URL {
        let (temporaryURL, response) = try await URLSession.shared.download(from: update.assetURL)

        guard
            let httpResponse = response as? HTTPURLResponse,
            (200..<300).contains(httpResponse.statusCode)
        else {
            throw UpdateError.downloadFailed
        }

        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
            ?? FileManager.default.homeDirectoryForCurrentUser
        let destinationURL = downloadsURL.appendingPathComponent(update.assetName)

        try? FileManager.default.removeItem(at: destinationURL)
        try FileManager.default.moveItem(at: temporaryURL, to: destinationURL)

        return destinationURL
    }

    private func latestRelease() async throws -> GitHubRelease {
        var request = URLRequest(url: Self.latestReleaseURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("\(AppInfo.name)/\(AppVersion.current.version)", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw UpdateError.releaseLookupFailed(statusCode: nil)
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw UpdateError.releaseLookupFailed(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder.github.decode(GitHubRelease.self, from: data)
        } catch {
            throw UpdateError.invalidReleaseData
        }
    }

    private static func normalizedVersion(_ version: String) -> String {
        version.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }

    private static func compareVersions(_ lhs: String, _ rhs: String) -> ComparisonResult {
        let lhsParts = versionParts(lhs)
        let rhsParts = versionParts(rhs)
        let count = max(lhsParts.count, rhsParts.count)

        for index in 0..<count {
            let left = index < lhsParts.count ? lhsParts[index] : 0
            let right = index < rhsParts.count ? rhsParts[index] : 0

            if left > right {
                return .orderedDescending
            }

            if left < right {
                return .orderedAscending
            }
        }

        return .orderedSame
    }

    private static func versionParts(_ version: String) -> [Int] {
        version
            .split { character in
                character == "." || character == "-"
            }
            .map { Int($0) ?? 0 }
    }

    private static let latestReleaseURL = URL(string: "https://api.github.com/repos/Binaryify/DockKey/releases/latest")!
}

private struct GitHubRelease: Decodable {
    let tagName: String
    let htmlURL: URL
    let body: String?
    let assets: [GitHubReleaseAsset]

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
        case body
        case assets
    }

    var preferredDownloadAsset: GitHubReleaseAsset? {
        assets.first { asset in
            asset.name.hasSuffix(".dmg")
                && asset.name.contains("arm64")
                && !asset.name.hasSuffix(".sha256")
        } ?? assets.first { asset in
            asset.name.hasSuffix(".dmg") && !asset.name.hasSuffix(".sha256")
        } ?? assets.first { asset in
            asset.name.hasSuffix(".zip") && !asset.name.hasSuffix(".sha256")
        }
    }
}

private struct GitHubReleaseAsset: Decodable {
    let name: String
    let browserDownloadURL: URL

    private enum CodingKeys: String, CodingKey {
        case name
        case browserDownloadURL = "browser_download_url"
    }
}

private enum UpdateError: LocalizedError {
    case releaseLookupFailed(statusCode: Int?)
    case invalidReleaseData
    case noDownloadAsset
    case downloadFailed

    var errorDescription: String? {
        switch self {
        case .releaseLookupFailed(let statusCode):
            if statusCode == 403 {
                return L10n.tr("update.error.rateLimited")
            }

            if statusCode == 404 {
                return L10n.tr("update.error.releaseNotFound")
            }

            return L10n.tr("update.error.lookupFailed")
        case .invalidReleaseData:
            return L10n.tr("update.error.invalidReleaseData")
        case .noDownloadAsset:
            return L10n.tr("update.error.noDownloadAsset")
        case .downloadFailed:
            return L10n.tr("update.error.downloadFailed")
        }
    }
}

private extension JSONDecoder {
    static var github: JSONDecoder {
        JSONDecoder()
    }
}
