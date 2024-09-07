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
                Label("操作", systemImage: "play.circle")
                    .tag(0)
                Label("设置", systemImage: "gear")
                    .tag(1)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 200)  // 增加最小宽度
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
        .navigationSplitViewStyle(.prominentDetail)  // 使用更突出的分割视图样式
    }
}

// 预览代码
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
