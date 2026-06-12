# DockKey

[English](README.md)

DockKey 是一个原生 Apple Silicon macOS 菜单栏小工具，用 `Command+数字` 快速切换 Dock 中的 App。

DockKey 面向 Apple Silicon Mac，默认只提供 `arm64` 版本。

## 安装

1. 打开下载好的 DMG。
2. 把 `DockKey.app` 拖到 `Applications`。
3. 从 `Applications` 打开 DockKey。

如果手动下载的版本被 macOS 拦截，或者提示 App 已损坏，安装后可以移除 quarantine 属性：

```sh
xattr -r -d com.apple.quarantine /Applications/DockKey.app
```

然后重新打开 DockKey。

## 功能

- 默认把 Dock 前 10 个 App 映射到 `Command+1` 到 `Command+0`。
- App 未运行时打开它；已运行但不在前台时切换到它。
- 对已在前台的 App 再次按同一个快捷键会隐藏它。
- Dock 顺序会自动刷新，也可以从菜单栏手动刷新。
- 支持把修饰键改为 Command、Option、Control 或 Shift。
- 支持显示/隐藏菜单栏图标。
- 支持显示/隐藏 Dock 图标。
- 支持登录后自动启动。
- 设置页显示版本号，并支持复制版本信息。
- 支持检查 GitHub Releases 更新，并下载最新 DMG。

## 为什么做 DockKey

这个项目的目标是替代很久没有更新的 [Snap](https://apps.apple.com/us/app/snap/id418073146) 这个 App。Snap 的功能很好，但 App Store 页面显示它的版本历史停在 2012 年的 1.5 版本；在 Apple Silicon Mac 上，Intel-only App 需要依赖 Rosetta。Apple 官方已经说明 Rosetta 会在未来 macOS 版本结束完整支持；macOS 28 开始，Rosetta 功能只会为部分老旧游戏保留有限兼容。

Apple 官方说明：[Using Intel-based apps on a Mac with Apple silicon](https://support.apple.com/en-us/102527)。

查看 [CHANGELOG.zh-CN.md](CHANGELOG.zh-CN.md) 了解版本历史。

## 说明

DockKey 读取本机 Dock 配置：

```text
~/Library/Preferences/com.apple.dock.plist
```

它使用 macOS 全局热键 API，因此自动 Dock 快捷键不需要辅助功能权限。

登录后自动启动使用用户级 LaunchAgent：

```text
~/Library/LaunchAgents/dev.binaryify.dockkey.loginitem.plist
```

## 开发

构建 App：

```sh
make app
```

生成的 App 位于：

```text
build/DockKey.app
```

指定版本号打包：

```sh
make app VERSION=0.3.0 BUILD_NUMBER=3
```

生成分发包：

```sh
make zip
make dmg
make release-artifacts
```

DMG 里包含 `DockKey.app` 和 `Applications` 快捷入口，方便拖拽安装。

开发期运行：

```sh
swift run DockKey
```

## 图标

重新生成图标资源：

```sh
swift Tools/generate_app_icon.swift
iconutil -c icns Assets/AppIcon.iconset -o Assets/AppIcon.icns
```

App 包内只携带紧凑版 `.icns` 和菜单栏模板图标；`AppIconPreview.png` 只用于本地预览。
