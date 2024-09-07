//
//  SettingVIew.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var frpcManager: FRPCManager

    var body: some View {
        Form {
            Section(header: Text("frpc config file")) {
                HStack {
                    Text(frpcManager.configFilePath ?? "-")
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose") {
                        frpcManager.selectConfigFile()
                    }
                }
            }
            Section(header: Text("frpc executable file path")) {
                HStack {
                    Text(frpcManager.executableFilePath ?? "-")
                        .truncationMode(.middle)
                    Spacer()
                    Button("Choose") {
                        frpcManager.selectExecutableFile()
                    }
                }
            }
            Section(header: Text("Startup settings")) {
                Toggle("Start on login", isOn: $frpcManager.startOnLogin)
                Toggle("Auto start frpc on app launch", isOn: $frpcManager.startOnAppLaunch)
            }
        }
        .formStyle(GroupedFormStyle())
        .navigationTitle("Settings")
        .padding()
    }
}
