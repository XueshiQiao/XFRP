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
            Section(header: Text("配置文件")) {
                HStack {
                    Text(frpcManager.configFilePath ?? "未选择")
                        .truncationMode(.middle)
                    Spacer()
                    Button("选择") {
                        frpcManager.selectConfigFile()
                    }
                }
            }
            Section(header: Text("可执行文件")) {
                HStack {
                    Text(frpcManager.executableFilePath ?? "未选择")
                        .truncationMode(.middle)
                    Spacer()
                    Button("选择") {
                        frpcManager.selectExecutableFile()
                    }
                }
            }
            Section(header: Text("启动设置")) {
                Toggle("开机自启动", isOn: $frpcManager.startOnLogin)
                Toggle("应用启动时自动启动FRPC", isOn: $frpcManager.startOnAppLaunch)
            }
        }
        .formStyle(GroupedFormStyle())
        .navigationTitle("设置")
        .padding()
    }
}
