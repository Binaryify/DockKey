import SwiftUI

struct PreferencesView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            settings
                .padding(EdgeInsets(top: 16, leading: 22, bottom: 20, trailing: 22))
        }
        .frame(width: 620, height: 500)
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
                Label(L10n.tr("button.refresh"), systemImage: "arrow.clockwise")
            }
            .labelStyle(.titleAndIcon)
            .keyboardShortcut("r", modifiers: [.command])
        }
        .padding(EdgeInsets(top: 10, leading: 22, bottom: 14, trailing: 22))
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 16) {
            SettingRow(title: L10n.tr("settings.language")) {
                Picker("", selection: $model.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 360)
            }

            SettingRow(title: L10n.tr("settings.modifier")) {
                Picker("", selection: $model.modifier) {
                    ForEach(HotKeyModifier.allCases) { modifier in
                        Text(modifier.title).tag(modifier)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 360)
            }

            SettingRow(title: L10n.tr("settings.currentShortcut")) {
                Text(L10n.tr("shortcut.range", model.modifier.symbol, model.modifier.symbol))
                    .foregroundStyle(.secondary)
            }

            Divider()

            SettingRow(title: L10n.tr("settings.statusBar")) {
                Toggle(L10n.tr("settings.showMenuBarIcon"), isOn: $model.showsStatusItem)
                    .toggleStyle(.switch)
            }

            SettingRow(title: L10n.tr("settings.dock")) {
                Toggle(L10n.tr("settings.showDockIcon"), isOn: $model.showsDockIcon)
                    .toggleStyle(.switch)
            }

            SettingRow(title: L10n.tr("settings.launchAtLogin")) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(isOn: Binding(
                        get: { model.launchAtLoginEnabled },
                        set: { model.setLaunchAtLoginEnabled($0) }
                    )) {
                        Text(L10n.tr("settings.launchAfterLogin"))
                    }
                    .toggleStyle(.switch)

                    if !model.launchAtLoginMessage.isEmpty {
                        Text(model.launchAtLoginMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            SettingRow(title: L10n.tr("settings.version")) {
                Text(AppVersion.current.displayText)
                    .foregroundStyle(.secondary)
            }

            SettingRow(title: L10n.tr("settings.updates")) {
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
                        Label(
                            model.isCheckingForUpdates ? L10n.tr("button.checking") : L10n.tr("button.checkUpdates"),
                            systemImage: "arrow.down.circle"
                        )
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
}

private struct SettingRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 118, alignment: .leading)

            content
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
