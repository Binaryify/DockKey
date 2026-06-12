import AppKit

enum AppIconProvider {
    static func appIcon(size: NSSize? = nil) -> NSImage {
        let image = image(named: "AppIcon", withExtension: "icns")
            ?? NSImage(named: NSImage.applicationIconName)
            ?? NSImage(systemSymbolName: "command", accessibilityDescription: AppInfo.name)
            ?? NSImage()

        if let size {
            image.size = size
        }

        return image
    }

    static func menuBarIcon() -> NSImage {
        let image = image(named: "MenuBarIconTemplate", withExtension: "png")
            ?? NSImage(systemSymbolName: "command", accessibilityDescription: AppInfo.name)
            ?? NSImage()

        image.size = NSSize(width: 21, height: 21)
        image.isTemplate = true

        return image
    }

    private static func image(named name: String, withExtension fileExtension: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: fileExtension) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }
}
