//
//  MainView.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
import UserNotificationsUI
import UserNotifications

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

                Button("强制终止FRPC") {
                    frpcManager.forceKillFRPC()
                }
                .foregroundColor(.red)
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
                        .frame(minHeight: 400, alignment: .topLeading)
                        .id("logEnd")
                }
                .onChange(of: frpcManager.cleanedConsoleOutput, initial: true, {
                    scrollView.scrollTo("logEnd", anchor: .bottom)
                })
            }
            .frame(height: 400)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .border(Color.gray, width: 1)
        }
        .navigationTitle("操作")
        .padding()
    }

}
