//
//  ContentView.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
import UserNotificationsUI
import UserNotifications

struct MainView: View {
    @EnvironmentObject var frpcManager: FRPCManager
    @State private var selectedTab: Int? = 0

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("操作", systemImage: "play.circle")
                    .tag(0)
                Label("设置", systemImage: "gear")
                    .tag(1)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 150)
        } detail: {
            NavigationStack {
                Group {
                    if let selectedTab = selectedTab {
                        switch selectedTab {
                        case 0:
                            ActionsView(frpcManager: frpcManager)
                        case 1:
                            SettingsView(frpcManager: frpcManager)
                        default:
                            Text("请在左侧选择一个选项")
                        }
                    } else {
                        Text("请在左侧选择一个选项")
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ActionsView: View {
    @ObservedObject var frpcManager: FRPCManager

    var body: some View {
        VStack {
            HStack {
                Button(frpcManager.isRunning ? "停止FRPC" : "启动FRPC") {
                    if frpcManager.isRunning {
                        frpcManager.stopFRPC()
                    } else {
                        frpcManager.startFRPC()
                    }
                }
                .padding()

                Button("验证配置") {
                    frpcManager.verifyConfig()
                }

                Button("重新加载配置") {
                    frpcManager.reloadConfig()
                }
                .disabled(!frpcManager.isRunning)

                Button("清除日志") {
                    frpcManager.clearLogs()
                }
            }

            ScrollViewReader { scrollView in
                ScrollView {
                    Text(frpcManager.cleanedConsoleOutput)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .green, .yellow, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            Text(frpcManager.cleanedConsoleOutput)
                                .font(.system(.body, design: .monospaced))
                                .foregroundColor(Color.black.opacity(0.1))
                                .textSelection(.enabled)
                        )
                        .frame(minHeight: 300, alignment: .topLeading)
                        .id("logEnd")
                }
                .onChange(of: frpcManager.cleanedConsoleOutput, initial: true, {
                    scrollView.scrollTo("logEnd", anchor: .bottom)
                })
            }
            .frame(height: 300)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .border(Color.gray, width: 1)
        }
        .navigationTitle("操作")
        .padding()
    }
}

// 预览代码
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
