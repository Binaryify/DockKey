# DockKey

[中文说明](README.zh-CN.md)

DockKey is a tiny native Apple Silicon macOS menu bar app for switching Dock apps with number shortcuts.

DockKey is built for Apple Silicon Mac and ships as an `arm64` app.

## Install

1. Open the downloaded DMG.
2. Drag `DockKey.app` to `Applications`.
3. Open DockKey from `Applications`.

If macOS blocks a manually downloaded build or says the app is damaged, remove the quarantine attribute after installing:

```sh
xattr -r -d com.apple.quarantine /Applications/DockKey.app
```

Then open DockKey again.

## Features

- Maps the first 10 Dock apps to `Command+1` through `Command+0` by default.
- Opens an app if it is not running, or activates it if it is already running.
- Pressing the same shortcut again hides the frontmost mapped app.
- Refreshes Dock order automatically and can also refresh manually from the menu bar.
- Supports Command, Option, Control, or Shift as the shortcut modifier.
- Can show or hide the menu bar icon.
- Can show or hide the Dock icon.
- Can start automatically after login.
- Shows the app version in settings and supports copying version info.
- Can check GitHub Releases for updates and download the latest DMG.

## Why DockKey

DockKey is designed as a modern Apple Silicon replacement for the long-unmaintained [Snap](https://apps.apple.com/us/app/snap/id418073146) app. Snap is still useful, but its App Store version history shows version 1.5 from 2012, and Intel-only apps on Apple Silicon depend on Rosetta. Apple states that full Rosetta support will end in a future macOS version, with macOS 28 keeping only limited compatibility for some older games.

Apple reference: [Using Intel-based apps on a Mac with Apple silicon](https://support.apple.com/en-us/102527).

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Notes

DockKey reads the local Dock preferences from:

```text
~/Library/Preferences/com.apple.dock.plist
```

It uses macOS global hot keys, so the automatic Dock shortcuts do not require Accessibility permission.

Launch at login uses a user LaunchAgent:

```text
~/Library/LaunchAgents/dev.binaryify.dockkey.loginitem.plist
```

## Development

Build the app:

```sh
make app
```

The generated app is:

```text
build/DockKey.app
```

Build with a specific version:

```sh
make app VERSION=0.3.0 BUILD_NUMBER=3
```

Create distributable archives:

```sh
make zip
make dmg
make release-artifacts
```

The DMG contains `DockKey.app` and an `Applications` shortcut for drag-and-drop installation.

Run during development:

```sh
swift run DockKey
```

## Icons

Regenerate icon assets:

```sh
swift Tools/generate_app_icon.swift
iconutil -c icns Assets/AppIcon.iconset -o Assets/AppIcon.icns
```

The app bundle only ships the compact `.icns` and the menu bar template icon. `AppIconPreview.png` is kept only for local inspection.
