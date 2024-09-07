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

struct MainView: View {
    @EnvironmentObject var frpcManager: FRPCManager
    @State private var selectedTab: Int? = 0

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Actions", systemImage: "play.circle").font(.headline)
                    .tag(0)
                Label("Settings", systemImage: "gear").font(.headline)
                    .tag(1)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 150, idealWidth: 150)
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

// 预览代码
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
