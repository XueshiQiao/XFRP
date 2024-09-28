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

enum Tab: Int {
    case FRPCAction = 0;
    case FRPCSettings = 1;
    case DockerImageMixed = 2;
}

struct MainView: View {
    @EnvironmentObject var frpcManager: FRPCManager
    @State private var selectedTab: Int = 0

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label(L10n.MainView.actions, systemImage: "play.circle").font(.headline)
                    .tag(Tab.FRPCAction.rawValue)
                
                Label(L10n.MainView.settings, systemImage: "gear").font(.headline)
                    .tag(Tab.FRPCSettings.rawValue)
                
                Label(L10n.MainView.dockerImage, systemImage: "sparkle.magnifyingglass").font(.headline)
                    .tag(Tab.DockerImageMixed.rawValue)
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 180, idealWidth: 180)
        } detail: {
            NavigationStack {
                Group {
                    switch selectedTab {
                    case Tab.FRPCAction.rawValue:
                        ActionsView(frpcManager: frpcManager)
                    case Tab.FRPCSettings.rawValue:
                        SettingsView(frpcManager: frpcManager)
                    case Tab.DockerImageMixed.rawValue:
                        DockerImageView()
                    default:
                        Text("error")
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
