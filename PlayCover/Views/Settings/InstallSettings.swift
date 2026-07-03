//
//  InstallSettings.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/9/22.
//

import SwiftUI

class InstallPreferences: NSObject, ObservableObject {
    static var shared = InstallPreferences()

    @objc @AppStorage("AlwaysInstallPlayTools") var alwaysInstallPlayTools = true

    @AppStorage("DefaultAppType") var defaultAppType: LSApplicationCategoryType = .none

    @AppStorage("ShowInstallPopup") var showInstallPopup = false

    @AppStorage("ShowAppStorePopup") var showAppStorePopup = true

    @AppStorage("CustomApplicationsDirectory") var customApplicationsDirectory = ""

    @AppStorage("CustomDownloadsDirectory") var customDownloadsDirectory = ""
}

struct InstallSettings: View {
    public static var shared = InstallSettings()

    @ObservedObject var installPreferences = InstallPreferences.shared

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("settings.applicationCategoryType")
                Spacer()
                Picker("", selection: installPreferences.$defaultAppType) {
                    ForEach(LSApplicationCategoryType.allCases, id: \.rawValue) { value in
                        Text(value.localizedName)
                            .tag(value)
                    }
                }
                .frame(width: 225)
            }
            Spacer()
                .frame(height: 20)
            Toggle("preferences.toggle.showAppStorePopup", isOn: $installPreferences.showAppStorePopup)
            Spacer()
                .frame(height: 20)
            Toggle("preferences.toggle.showInstallPopup", isOn: $installPreferences.showInstallPopup)
            GroupBox {
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Toggle("preferences.toggle.alwaysInstallPlayTools",
                                   isOn: $installPreferences.alwaysInstallPlayTools)
                        }
                        Spacer()
                    }
                    Spacer()
                        .frame(height: 20)
                }
            }.disabled(installPreferences.showInstallPopup)

            Spacer()
                .frame(height: 20)

            // MARK: - Custom Applications Directory
            DirectoryPickerCard(
                titleKey: "preferences.installPath.title",
                descriptionKey: "preferences.installPath.description",
                defaultKey: "preferences.installPath.default",
                chooseKey: "preferences.installPath.choose",
                resetKey: "preferences.installPath.reset",
                panelMessageKey: "preferences.installPath.panelMessage",
                warningKey: "preferences.installPath.warning",
                path: $installPreferences.customApplicationsDirectory
            )

            Spacer()
                .frame(height: 20)

            // MARK: - Custom Downloads Directory
            DirectoryPickerCard(
                titleKey: "preferences.downloadPath.title",
                descriptionKey: "preferences.downloadPath.description",
                defaultKey: "preferences.downloadPath.default",
                chooseKey: "preferences.downloadPath.choose",
                resetKey: "preferences.downloadPath.reset",
                panelMessageKey: "preferences.downloadPath.panelMessage",
                warningKey: nil,
                path: $installPreferences.customDownloadsDirectory
            )
        }
        .padding(20)
        .frame(width: 600, height: 540)
        .onChange(of: installPreferences.customApplicationsDirectory) { _ in
            AppsVM.shared.fetchApps()
        }
    }
}

struct DirectoryPickerCard: View {
    let titleKey: String
    let descriptionKey: String
    let defaultKey: String
    let chooseKey: String
    let resetKey: String
    let panelMessageKey: String
    let warningKey: String?

    @Binding var path: String

    var body: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(titleKey)
                            .font(.headline)
                        Text(descriptionKey)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                HStack {
                    Text(path.isEmpty
                         ? NSLocalizedString(defaultKey, comment: "")
                         : path)
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(path.isEmpty ? defaultPathDisplay : path)

                    Spacer()

                    Button(chooseKey) {
                        selectDirectory()
                    }

                    if !path.isEmpty {
                        Button(resetKey) {
                            path = ""
                        }
                    }
                }

                if let warningKey = warningKey, !path.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(warningKey)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }
                }
            }
            .padding(8)
        }
        .glassCard(cornerRadius: 12)
    }

    private var defaultPathDisplay: String {
        if titleKey == "preferences.installPath.title" {
            return PlayTools.appInstallDirectory.path
        }
        return NSLocalizedString(defaultKey, comment: "")
    }

    private func selectDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = NSLocalizedString(chooseKey, comment: "")
        panel.message = NSLocalizedString(panelMessageKey, comment: "")

        panel.begin { response in
            Task { @MainActor in
                guard response == .OK, let url = panel.url else { return }
                let selectedPath = url.path

                // Verify the selected directory is writable
                if FileManager.default.isWritableFile(atPath: selectedPath) {
                    path = selectedPath
                } else {
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("preferences.installPath.error.title", comment: "")
                    alert.informativeText = NSLocalizedString("preferences.installPath.error.message", comment: "")
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: NSLocalizedString("button.OK", comment: ""))
                    alert.runModal()
                }
            }
        }
    }
}
