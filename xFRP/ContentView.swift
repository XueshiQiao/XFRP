//
//  ContentView.swift
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
    @Published var consoleOutput = ""
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

    private var process: Process?

    init() {
        loadBookmark(key: "frpcConfigBookmark") { url in
            self.configFilePath = url.path
        }
        loadBookmark(key: "frpcExecutableBookmark") { url in
            self.executableFilePath = url.path
        }
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
            // 检查可执行文件是否存在
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
                        print("发送通知失败: \(error.localizedDescription)")
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
}

struct ContentView: View {
    @EnvironmentObject var frpcManager: FRPCManager
    @State private var selectedTab = 0

    var body: some View {
        NavigationView {
            List {
                NavigationLink(destination: SettingsView(frpcManager: frpcManager), tag: 0, selection: Binding<Int?>(get: { selectedTab }, set: { selectedTab = $0 ?? 0 })) {
                    Label("设置", systemImage: "gear")
                }
                NavigationLink(destination: ActionsView(frpcManager: frpcManager), tag: 1, selection: Binding<Int?>(get: { selectedTab }, set: { selectedTab = $0 ?? 0 })) {
                    Label("操作", systemImage: "play.circle")
                }
            }
            .listStyle(SidebarListStyle())
            .frame(minWidth: 150)

            Text("请在左侧选择一个选项")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct SettingsView: View {
    @ObservedObject var frpcManager: FRPCManager

    var body: some View {
        Form {
            Section(header: Text("配置文件")) {
                HStack {
                    Text(frpcManager.configFilePath ?? "未选择")
                        .truncationMode(.middle)
                    Spacer()
                    Button("选择") {
                        frpcManager.selectConfigFile()
                    }
                }
            }
            Section(header: Text("可执行文件")) {
                HStack {
                    Text(frpcManager.executableFilePath ?? "未选择")
                        .truncationMode(.middle)
                    Spacer()
                    Button("选择") {
                        frpcManager.selectExecutableFile()
                    }
                }
            }
        }
        .navigationTitle("设置")
        .padding()
    }
}

struct ActionsView: View {
    @ObservedObject var frpcManager: FRPCManager

    var body: some View {
        VStack {
            Button(frpcManager.isRunning ? "停止FRPC" : "启动FRPC") {
                if frpcManager.isRunning {
                    frpcManager.stopFRPC()
                } else {
                    frpcManager.startFRPC()
                }
            }
            .padding()

            ScrollView {
                Text(frpcManager.consoleOutput)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .foregroundColor(.primary)
                    .background(
                        Text(frpcManager.consoleOutput)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .green, .yellow, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .mask(
                                Text(frpcManager.consoleOutput)
                                    .font(.system(.body, design: .monospaced))
                                    .textSelection(.enabled)
                            )
                    )
            }
            .frame(height: 300)
            .border(Color.gray, width: 1)
        }
        .navigationTitle("操作")
        .padding()
    }
}

// 预览代码
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
