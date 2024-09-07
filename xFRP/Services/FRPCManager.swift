//
//  FRPCManager.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//

import SwiftUI
import Foundation
import UniformTypeIdentifiers
import UserNotificationsUI
import UserNotifications

class FRPCManager: ObservableObject {

    @Published var isRunning = false
    @Published var consoleOutput = "abc" {
        didSet {
            cleanedConsoleOutput = removeANSIEscapeCodes(from: consoleOutput)
        }
    }
    @Published var cleanedConsoleOutput = ""

    @Published var configFilePath: String? {
        didSet {
            if let path = configFilePath {
                saveBookmark(for: URL(fileURLWithPath: path), key: "frpcConfigBookmark")
            }
        }
    }
    @Published var executableFilePath: String? {
        didSet {
            if let path = executableFilePath {
                saveBookmark(for: URL(fileURLWithPath: path), key: "frpcExecutableBookmark")
            }
        }
    }

    @Published var startOnLogin: Bool {
        didSet {
            UserDefaults.standard.set(startOnLogin, forKey: "startOnLogin")
            AppDelegate.instance.updateLoginItem()
        }
    }

    @Published var startOnAppLaunch: Bool {
        didSet {
            UserDefaults.standard.set(startOnAppLaunch, forKey: "startOnAppLaunch")
        }
    }

    private var process: Process?

    init() {
        consoleOutput = "\n"
        startOnLogin = UserDefaults.standard.bool(forKey: "startOnLogin")
        startOnAppLaunch = UserDefaults.standard.bool(forKey: "startOnAppLaunch")

        loadBookmark(key: "frpcConfigBookmark") { url in
            self.configFilePath = url.path
        }
        loadBookmark(key: "frpcExecutableBookmark") { url in
            self.executableFilePath = url.path
        }
    }
    
    deinit {
        stopFRPC()
    }

    private func loadBookmark(key: String, completion: (URL) -> Void) {
        if let bookmarkData = UserDefaults.standard.data(forKey: key) {
            do {
                var isStale = false
                let url = try URL(resolvingBookmarkData: bookmarkData, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                if !isStale {
                    _ = url.startAccessingSecurityScopedResource()
                    completion(url)
                }
            } catch {
                print("无法解析书签：\(error)")
            }
        }
    }

    func selectConfigFile() {
        selectFile(contentTypes: [UTType.yaml, UTType.text]) { url in
            self.configFilePath = url.path
        }
    }

    func selectExecutableFile() {
        selectFile(contentTypes: [UTType.executable]) { url in
            self.executableFilePath = url.path
        }
    }

    private func selectFile(contentTypes: [UTType], completion: @escaping (URL) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = contentTypes

        if openPanel.runModal() == .OK {
            if let url = openPanel.url {
                completion(url)
            }
        }
    }

    private func saveBookmark(for url: URL, key: String) {
        do {
            let bookmarkData = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(bookmarkData, forKey: key)
        } catch {
            print("无法创建书签：\(error)")
            consoleOutput += "无法创建书签：\(error.localizedDescription)\n"
        }
    }

    func startFRPC() {
        guard let configPath = configFilePath, let executablePath = executableFilePath else {
            consoleOutput += "请先选择配置文件和可执行文件\n"
            return
        }

        isRunning = true
        process = Process()
        process?.executableURL = URL(fileURLWithPath: executablePath)
        process?.arguments = ["-c", configPath]

        let pipe = Pipe()
        process?.standardOutput = pipe
        process?.standardError = pipe

        do {
            // 检查可执行���件是否存在
            let fileManager = FileManager.default
            guard fileManager.fileExists(atPath: executablePath) else {
                consoleOutput += "启动FRPC失败: 可执行文件不存在\n"
                isRunning = false
                showErrorNotification(str: "启动FRPC失败: 可执行文件不存在")
                return
            }

            // 检查文件权限
            guard fileManager.isExecutableFile(atPath: executablePath) else {
                consoleOutput += "启动FRPC失败: 无法执行所选文件。请确保应用程序有足够的权限来执行此文件。\n"
                consoleOutput += "您可能需要在系统偏好设置中授予应用程序完全磁盘访问权限。\n"
                isRunning = false
                showErrorNotification(str: "启动FRPC失败: 无法执行所选文件。请确保应用程序有足够的权限来执行此文件。您可能需要在系统偏好设置中授予应用程序完全磁盘访问权限。\n")
                return
            }

            try process?.run()

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                    DispatchQueue.main.async {
                        self.consoleOutput += output
                    }
                }
            }
        } catch {
            consoleOutput += "启动FRPC失败: \(error.localizedDescription)\n"
            showErrorNotification(str: error.localizedDescription)
            if let process = process, !process.isRunning {
                consoleOutput += "进程未能成功启动，请检查文件路径和权限\n"
            }
            isRunning = false

        }
    }

    func stopFRPC() {
        process?.terminate()
        isRunning = false
        consoleOutput += "FRPC已停止\n"
    }
    
    func showErrorNotification(str: String) {
        // 发送本地通知
        let content = UNMutableNotificationContent()
        content.title = "FRPC启动失败"
        content.body = str
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)

        // 请求通知权限
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                UNUserNotificationCenter.current().add(request) { error in
                    if let error = error {
                        print("发送��知失败: \(error.localizedDescription)")
                    } else {
                        print("通知已成功发送")
                    }
                }
            } else {
                print("用户未授予通知权限")
            }
        }

        // 在主线程上显示通知
        DispatchQueue.main.async {
            NSApp.requestUserAttention(.criticalRequest)
        }
    }

    private func removeANSIEscapeCodes(from string: String) -> String {
        let pattern = "\u{001B}\\[[0-9;]*[mGK]"
        return string.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }

    func verifyConfig() {
        guard let configPath = configFilePath, let executablePath = executableFilePath else {
            consoleOutput += "请先选择配置文件和可执行文件\n"
            return
        }

        let verifyProcess = Process()
        verifyProcess.executableURL = URL(fileURLWithPath: executablePath)
        verifyProcess.arguments = ["verify", "-c", configPath]

        let pipe = Pipe()
        verifyProcess.standardOutput = pipe
        verifyProcess.standardError = pipe

        do {
            try verifyProcess.run()
            verifyProcess.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.consoleOutput += "配置验证结果：\n\(output)\n"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.consoleOutput += "验证配置失败: \(error.localizedDescription)\n"
            }
        }
    }

    func reloadConfig() {
        guard let configPath = configFilePath, let executablePath = executableFilePath else {
            consoleOutput += "请先选择配置文件和可执行文件\n"
            return
        }

        let reloadProcess = Process()
        reloadProcess.executableURL = URL(fileURLWithPath: executablePath)
        reloadProcess.arguments = ["reload", "-c", configPath]

        let pipe = Pipe()
        reloadProcess.standardOutput = pipe
        reloadProcess.standardError = pipe

        do {
            try reloadProcess.run()
            reloadProcess.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.consoleOutput += "重新加载配置结果：\n\(output)\n"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.consoleOutput += "重新加载配置失败: \(error.localizedDescription)\n"
            }
        }
    }

    func clearLogs() {
        DispatchQueue.main.async {
            self.consoleOutput = ""
        }
    }
}
