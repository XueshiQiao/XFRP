//
//  xFRPApp.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//
import SwiftUI
import Foundation
import Combine
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    static private(set) var instance: AppDelegate! = nil
    private var statusItem: NSStatusItem?
    @Published var frpcManager = FRPCManager()
    // 监听FRPC状态变化
    // 创建一个 AnyCancellable 属性来存储订阅
    private var cancellable: Combine.AnyCancellable?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.instance = self
        setupMenuBar()

        // 检查是否需要在应用启动时自动启动FRPC
        if frpcManager.startOnAppLaunch {
            frpcManager.startFRPC()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if frpcManager.isRunning {
            print("Stop running frpcManager")
            frpcManager.stopFRPC()
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "FRPC状态")
        }

        let menu = NSMenu()

        let showWindow = NSMenuItem(title: "Show Main Window", action: #selector(showMainWindow), keyEquivalent: "")
        menu.addItem(showWindow)

        let statusMenuItem = NSMenuItem(title: "FRPC未运行", action: nil, keyEquivalent: "")
        menu.addItem(statusMenuItem)

        menu.addItem(NSMenuItem.separator())

        let startStopMenuItem = NSMenuItem(title: "启动FRPC", action: #selector(toggleFRPC), keyEquivalent: "")
        menu.addItem(startStopMenuItem)

        menu.addItem(NSMenuItem.separator())
        let exitMenuItem = NSMenuItem(title: "Exit", action: #selector(exitApp), keyEquivalent: "q")
        menu.addItem(exitMenuItem)

        statusItem?.menu = menu

        // 在 init() 或其他适当的地方设置订阅
        cancellable = frpcManager.$isRunning.sink { [weak self] isRunning in
            self?.updateMenuBar(isRunning: isRunning)
        }
    }

    @objc private func showMainWindow() {
        if let window = NSApplication.shared.windows.first(where: { $0.canBecomeKey }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            print("No window found that can become key")
        }
    }

    @objc private func exitApp() {
        if frpcManager.isRunning {
            frpcManager.stopFRPC()
        }
        NSApplication.shared.terminate(nil)
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
            //0 for "show main window"
            if let statusMenuItem = menu.item(at: 1) {
                statusMenuItem.title = isRunning ? "FRPC正在运行" : "FRPC未运行"
            }
            //2 for separator
            if let startStopMenuItem = menu.item(at: 3) {
                startStopMenuItem.title = isRunning ? "停止FRPC" : "启动FRPC"
            }
        }
    }

    func updateLoginItem() {
        _ = Bundle.main.bundleIdentifier ?? ""
        let appService = SMAppService.mainApp

        do {
            if frpcManager.startOnLogin {
                try appService.register()
            } else {
                try appService.unregister()
            }
        } catch {
            print("更新登录项失败: \(error.localizedDescription)")
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
