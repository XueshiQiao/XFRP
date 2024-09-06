//
//  ContentView.swift
//  xFRP
//
//  Created by Xueshi Qiao on 9/7/24.
//

import SwiftUI
import Foundation

class FRPCManager: ObservableObject {
    @Published var isRunning = false
    @Published var consoleOutput = ""
    private var process: Process?
    @Published var configFilePath: String?

    func selectConfigFile() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.yaml, .text,]

        if openPanel.runModal() == .OK {
            configFilePath = openPanel.url?.path
        }
    }

    func startFRPC() {
        guard let configPath = configFilePath else {
            consoleOutput += "请先选择配置文件\n"
            return
        }

        isRunning = true
        process = Process()
        process?.executableURL = Bundle.main.url(forResource: "frpc", withExtension: nil)
        // process?.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/frpc")
        process?.arguments = ["-c", configPath]


        let pipe = Pipe()
        process?.standardOutput = pipe
        process?.standardError = pipe

        do {
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
            isRunning = false
        }
    }

    func stopFRPC() {
        process?.terminate()
        isRunning = false
        consoleOutput += "FRPC已停止\n"
    }
}

struct ContentView: View {
    @StateObject private var frpcManager = FRPCManager()
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
