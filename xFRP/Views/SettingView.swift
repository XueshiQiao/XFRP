//
//  SettingVIew.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var frpcManager: FRPCManager
    @AppStorage("AppLanguage") private var language = "en"

    var body: some View {
        Form {
            Section(header: Text(L10n.Settings.configFile)) {
                HStack {
                    Text(frpcManager.configFilePath ?? "-")
                        .truncationMode(.middle)
                    Spacer()
                    Button(L10n.Settings.choose) {
                        frpcManager.selectConfigFile()
                    }
                }
            }
            Section(header: Text(L10n.Settings.executableFile)) {
                HStack {
                    Text(frpcManager.executableFilePath ?? "-")
                        .truncationMode(.middle)
                    Spacer()
                    Button(L10n.Settings.choose) {
                        frpcManager.selectExecutableFile()
                    }
                }
            }
            Section(header: Text(L10n.Settings.startupSettings)) {
                Toggle(L10n.Settings.startOnLogin, isOn: $frpcManager.startOnLogin)
                Toggle(L10n.Settings.autoStartOnLaunch, isOn: $frpcManager.startOnAppLaunch)
            }
            Section(header: Text(L10n.Settings.language)) {
                Picker(L10n.Settings.chooseLanguage, selection: $language) {
                    Text("English").tag("en")
                    Text("中文").tag("zh-Hans")
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .formStyle(GroupedFormStyle())
        .navigationTitle(L10n.Settings.title)
        .padding()
    }
}
