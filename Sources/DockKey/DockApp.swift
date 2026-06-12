import AppKit

struct DockApp: Identifiable {
    let url: URL
    let name: String
    let bundleIdentifier: String?
    let icon: NSImage

    var id: String {
        bundleIdentifier ?? url.path
    }
}
