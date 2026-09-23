import AppKit
import Combine
import Foundation

struct AgentGuardClient: Decodable, Identifiable {
    let id: String
    let name: String
    let installed: Bool
    let approvalReason: String
}

@MainActor
final class AgentGuardController: ObservableObject {
    static let shared = AgentGuardController()
    @Published private(set) var clients: [AgentGuardClient] = []
    @Published private(set) var isWorking = false
    @Published private(set) var message = "检测后可安装守卫；不自动开启免确认"
    private var details = ""

    func refresh() { run("status") }
    func install(_ client: AgentGuardClient) { run("install", client: client.id) }
    func uninstall(_ client: AgentGuardClient) { run("uninstall", client: client.id) }

    func copyDetails() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(details.isEmpty ? message : details, forType: .string)
    }

    private func run(_ action: String, client: String? = nil) {
        guard !isWorking else { return }
        guard let script = Bundle.main.url(forResource: "manage", withExtension: "py", subdirectory: "AgentGuard") else {
            message = "守卫资源缺失，请重新构建或安装 TermYes"
            return
        }
        isWorking = true
        message = action == "status" ? "正在检测守卫配置…" : "正在处理守卫文件，请稍候…"
        let arguments = [script.path, action] + (client.map { [$0] } ?? [])
        Task {
            let result = await Task.detached(priority: .userInitiated) {
                Self.execute(arguments)
            }.value
            details = String(decoding: result.1, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            if result.0 == 0, action == "status" {
                do {
                    clients = try JSONDecoder().decode([AgentGuardClient].self, from: result.1)
                    message = "安装状态不代表客户端已加载；免确认均待实测"
                } catch {
                    message = "守卫状态无法解析；请复制详情检查"
                }
            } else {
                message = String(details.prefix(120))
            }
            if result.0 == 0, action != "status" {
                // Refresh counts without replacing the actionable install/restore result.
                let status = await Task.detached(priority: .userInitiated) {
                    Self.execute([script.path, "status"])
                }.value
                if status.0 == 0, let value = try? JSONDecoder().decode([AgentGuardClient].self, from: status.1) {
                    clients = value
                }
            }
            isWorking = false
        }
    }

    nonisolated private static func execute(_ arguments: [String]) -> (Int32, Data) {
        // /usr/bin/python3 may otherwise open the macOS developer-tools installer.
        let developerTools = Process()
        developerTools.executableURL = URL(fileURLWithPath: "/usr/bin/xcode-select")
        developerTools.arguments = ["-p"]
        developerTools.standardOutput = FileHandle.nullDevice
        developerTools.standardError = FileHandle.nullDevice
        do {
            try developerTools.run()
            developerTools.waitUntilExit()
            guard developerTools.terminationStatus == 0 else {
                return (1, Data("守卫需要可用的 /usr/bin/python3（Xcode Command Line Tools）；未自动安装依赖。".utf8))
            }
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
            process.arguments = arguments
            process.standardOutput = pipe
            process.standardError = pipe
            process.environment = ProcessInfo.processInfo.environment.merging(["PYTHONDONTWRITEBYTECODE": "1"]) { _, new in new }
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return (process.terminationStatus, data)
        } catch {
            return (1, Data("无法运行守卫管理器：\(error.localizedDescription)".utf8))
        }
    }
}
