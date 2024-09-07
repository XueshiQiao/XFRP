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
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 20) {
            actionButtons
            logView
        }
        .navigationTitle("操作")
        .background(Color(.windowBackgroundColor))
    }

    private var actionButtons: some View {
        HStack(spacing: 15) {
            ActionButton(title: frpcManager.isRunning ? "停止FRPC" : "启动FRPC",
                         icon: frpcManager.isRunning ? "stop.circle" : "play.circle",
                         color: frpcManager.isRunning ? .red : .green) {
                frpcManager.isRunning ? frpcManager.stopFRPC() : frpcManager.startFRPC()
            }

            ActionButton(title: "验证配置", icon: "checkmark.shield", color: .blue) {
                frpcManager.verifyConfig()
            }

            ActionButton(title: "重载配置", icon: "arrow.clockwise", color: .orange) {
                frpcManager.reloadConfig()
            }
            .disabled(!frpcManager.isRunning)

            ActionButton(title: "强制终止", icon: "xmark.octagon", color: .red) {
                frpcManager.forceKillFRPC()
            }

            ActionButton(title: "清除日志", icon: "trash", color: .gray) {
                frpcManager.clearLogs()
            }
            .disabled(frpcManager.cleanedConsoleOutput.isEmpty)
        }
        .padding()
    }

    private var logView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                Text(frpcManager.cleanedConsoleOutput.isEmpty ? " " : frpcManager.cleanedConsoleOutput)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .green, .yellow, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Text(frpcManager.cleanedConsoleOutput.isEmpty ? " " : frpcManager.cleanedConsoleOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(Color.black.opacity(0.1))
                            .textSelection(.enabled)
                    )
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 400, alignment: .topLeading)
                    .id("logEnd")
            }
            .onChange(of: frpcManager.cleanedConsoleOutput, initial: true, {
                scrollView.scrollTo("logEnd", anchor: .bottom)
            })
        }
        .padding(8.0)
        .background(Color(.controlBackgroundColor))
        // .cornerRadius(10)
        // .shadow(radius: 5)



////

    //         .frame(height: 400)
    //         .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
    //         .border(Color.gray, width: 1)
    //     }
    //     .navigationTitle("Actions")
    //     .padding()
    // }


///


    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(color)
            .frame(width: 60, height: 60)
        }
    }
}
