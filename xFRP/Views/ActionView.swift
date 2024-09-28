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
            ActionButton(title: frpcManager.isRunning ? L10n.Actions.stop : L10n.Actions.start,
                         icon: frpcManager.isRunning ? "stop.circle" : "play.circle",
                         color: frpcManager.isRunning ? .red : .green) {
                frpcManager.isRunning ? frpcManager.stopFRPC() : frpcManager.startFRPC()
            }

            ActionButton(title: L10n.Actions.verify, icon: "checkmark.shield", color: .blue) {
                frpcManager.verifyConfig()
            }

            ActionButton(title: L10n.Actions.reload, icon: "arrow.clockwise", color: .orange) {
                frpcManager.reloadConfig()
            }
            .disabled(!frpcManager.isRunning)

            ActionButton(title: L10n.Actions.forceStop, icon: "xmark.octagon", color: .red) {
                frpcManager.forceKillFRPC()
            }

            ActionButton(title: L10n.Actions.clearLogs, icon: "trash", color: .gray) {
                frpcManager.clearLogs()
            }
            .disabled(frpcManager.cleanedConsoleOutput.isEmpty)
        }
        .padding(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
    }

    private var logView: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                Text(frpcManager.cleanedConsoleOutput.isEmpty ? " " : frpcManager.cleanedConsoleOutput)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .green, .yellow, .red],
                            startPoint: .leading,
                            endPoint: .trailing
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
        .padding(EdgeInsets(top: 0, leading: 8, bottom: 8, trailing: 8))
        .background(Color(.controlBackgroundColor))
        .cornerRadius(10)
        .shadow(radius: 5)
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
