# Changelog

[中文变更日志](CHANGELOG.zh-CN.md)

All notable changes to DockKey will be documented in this file.

## Unreleased

## 0.4.0 - 2026-06-12

### Added

- Added English and Simplified Chinese localization with a follow-system default and manual language picker.
- Double-clicking DockKey now opens the settings window while launch-at-login stays quiet.

### Fixed

- Fixed GitHub Release parsing for update checks.

## 0.3.0 - 2026-06-12

### Changed

- Hides the internal build number from the visible version text.

### Documentation

- Added the quarantine removal command for manually downloaded builds.

## 0.2.0 - 2026-06-12

### Added

- Added manual update checks from the settings window and menu bar menu.
- Downloads the latest GitHub Release DMG automatically when a newer version is available.
- Added `Command+Q` quit support when DockKey is active.

### Changed

- Simplified the app menu by keeping only About and Quit.

## 0.1.0

### Added

- Initial Apple Silicon `arm64` DockKey app.
- Dock app switching with `Command+1` through `Command+0`.
- Toggle behavior for frontmost mapped apps.
- Menu bar and Dock visibility settings.
- Launch at login support.
- Version display and copy action.
- Zip and DMG packaging.
