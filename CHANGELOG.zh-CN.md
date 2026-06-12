# 变更日志

[English changelog](CHANGELOG.md)

这里记录 DockKey 的重要变更。

## Unreleased

## 0.4.0 - 2026-06-12

### Added

- 新增 App 界面的英文和简体中文本地化，默认跟随系统，也支持手动切换。
- 双击打开 DockKey 时会展示设置窗口，登录自动启动时仍保持静默。

### Fixed

- 修复检查更新时 GitHub Release 数据解析失败的问题。

## 0.3.0 - 2026-06-12

### Changed

- 版本展示不再显示内部 build number。

### Documentation

- 补充手动下载版本被 quarantine 拦截时的解除命令。

## 0.2.0 - 2026-06-12

### Added

- 在设置窗口和菜单栏菜单中新增手动检查更新。
- 当 GitHub Release 有新版本时，自动下载最新 DMG。
- DockKey 激活时支持 `Command+Q` 退出。

### Changed

- 精简应用菜单，只保留关于和退出。

## 0.1.0

### Added

- 初始 Apple Silicon `arm64` DockKey App。
- 支持 `Command+1` 到 `Command+0` 切换 Dock App。
- 对已在前台的映射 App，再次按同一快捷键会隐藏。
- 支持菜单栏图标和 Dock 图标显示设置。
- 支持登录后自动启动。
- 支持版本号显示和复制。
- 支持 zip 和 DMG 打包。
