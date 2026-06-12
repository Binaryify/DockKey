import SwiftUI

struct PreferencesView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            settings
                .padding(EdgeInsets(top: 20, leading: 22, bottom: 22, trailing: 22))
        }
        .frame(width: 560, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        HStack(spacing: 14) {
            Image(nsImage: AppIconProvider.appIcon(size: NSSize(width: 54, height: 54)))
                .resizable()
                .frame(width: 54, height: 54)
                .accessibilityLabel(AppInfo.name)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppInfo.name)
                    .font(.system(size: 24, weight: .semibold))

                Text(model.hotKeyStatus)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                model.refreshDockApps(force: true)
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }
            .labelStyle(.titleAndIcon)
            .keyboardShortcut("r", modifiers: [.command])
        }
        .padding(EdgeInsets(top: 18, leading: 22, bottom: 14, trailing: 22))
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingRow(title: "修饰键") {
                Picker("", selection: $model.modifier) {
                    ForEach(HotKeyModifier.allCases) { modifier in
                        Text(modifier.title).tag(modifier)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 360)
            }

            SettingRow(title: "当前组合") {
                Text("\(model.modifier.symbol)1 到 \(model.modifier.symbol)0")
                    .foregroundStyle(.secondary)
            }

            Divider()

            SettingRow(title: "状态栏") {
                Toggle("显示菜单栏图标", isOn: $model.showsStatusItem)
                    .toggleStyle(.switch)
            }

            SettingRow(title: "Dock") {
                Toggle("显示 Dock 图标", isOn: $model.showsDockIcon)
                    .toggleStyle(.switch)
            }

            SettingRow(title: "开机启动") {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLoginEnabled($0) }
                    )) {
                        Text("登录后自动启动")
                    }
                    .toggleStyle(.switch)

                    if !model.launchAtLoginMessage.isEmpty {
                        Text(model.launchAtLoginMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            SettingRow(title: "版本") {
                HStack(spacing: 10) {
                    Text(AppVersion.current.displayText)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        copyVersion()
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                }
            }

            SettingRow(title: "更新") {
                HStack(spacing: 10) {
                    if !model.updateStatus.isEmpty {
                        Text(model.updateStatus)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        model.checkForUpdates()
                    } label: {
                        Label(model.isCheckingForUpdates ? "检查中" : "检查更新", systemImage: "arrow.down.circle")
                    }
                    .disabled(model.isCheckingForUpdates)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .textBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }

    private func copyVersion() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(AppVersion.current.copyText, forType: .string)
    }
}

private struct SettingRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 76, alignment: .leading)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
