//
//  xFRPApp.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//
import SwiftUI
import Foundation
import Combine

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    private var statusItem: NSStatusItem?
    @Published var frpcManager = FRPCManager()
    // 监听FRPC状态变化
    // 创建一个 AnyCancellable 属性来存储订阅
    private var cancellable: Combine.AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "FRPC状态")
        }

        let menu = NSMenu()

        let statusMenuItem = NSMenuItem(title: "FRPC未运行", action: nil, keyEquivalent: "")
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let startStopMenuItem = NSMenuItem(title: "启动FRPC", action: #selector(toggleFRPC), keyEquivalent: "")
        menu.addItem(startStopMenuItem)

        statusItem?.menu = menu


        // 在 init() 或其他适当的地方设置订阅
        cancellable = frpcManager.$isRunning.sink { [weak self] isRunning in
            self?.updateMenuBar(isRunning: isRunning)
        }
    }

    @objc private func toggleFRPC() {
        if frpcManager.isRunning {
            frpcManager.stopFRPC()
        } else {
            frpcManager.startFRPC()
        }
    }

    private func updateMenuBar(isRunning: Bool) {
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: isRunning ? "circle.fill" : "circle", accessibilityDescription: "FRPC状态")
        }

        if let menu = statusItem?.menu {
            if let statusMenuItem = menu.item(at: 0) {
                statusMenuItem.title = isRunning ? "FRPC正在运行" : "FRPC未运行"
            }

            if let startStopMenuItem = menu.item(at: 2) {
                startStopMenuItem.title = isRunning ? "停止FRPC" : "启动FRPC"
            }
        }
    }
}

@main
struct xFRPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appDelegate.frpcManager)
        }
    }
}
