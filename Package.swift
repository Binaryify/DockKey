// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "DockKey",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "DockKey", targets: ["DockKey"])
    ],
    targets: [
        .executableTarget(name: "DockKey")
    ]
)
