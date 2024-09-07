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

                Button("Verify config file") {
                    frpcManager.verifyConfig()
                }

                Button("Reload config") {
                    frpcManager.reloadConfig()
                }
                .disabled(!frpcManager.isRunning)

                Button("pkill frpc") {
                    frpcManager.forceKillFRPC()
                }
                .foregroundColor(.red)

                Button("Clear logs") {
                    frpcManager.clearLogs()
                }.disabled(frpcManager.cleanedConsoleOutput.isEmpty)
            }

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
            .frame(height: 400)
            .padding(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
            .border(Color.gray, width: 1)
        }
        .navigationTitle("Actions")
        .padding()
    }

}
