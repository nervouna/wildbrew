import Foundation
import Testing
import WildbrewCore
@testable import Wildbrew

struct PrivilegedSupervisorTests {
  @Test func supervisorCancelsNestedChildrenAndRejectsLateLaunch() async throws {
    let folder = URL.temporaryDirectory.appending(path: "wildbrew-supervisor '" + UUID().uuidString)
    try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
    defer { try? FileManager.default.removeItem(at: folder) }
    let marker = folder.appending(path: "late marker")
    let payload = "quote ' dollar $ and newline\n"
    let supervisor = try PrivilegedSupervisor()
    var settings = BrewSettings(); settings.workingDirectory = folder.path
    let command = BrewCommand(executable: "/bin/sh", arguments: ["-c", "printf '%s' \"$1\"; (sleep 1; touch \"$2\") & wait", "sh", payload, marker.path], title: "运行测试")
    let record = TaskRecord(command: command, settings: settings, destination: .log)
    let execution = BrewCommand(executable: "/bin/sh", arguments: ["-c", supervisor.shellCommand(shell: record.shellCommand, title: "运行测试", mutatesState: false)], title: "运行测试")
    let running = Task { try await BrewRunner().run(execution, settings: settings) }
    try await Task.sleep(for: .milliseconds(200))
    supervisor.cancel()
    let result = try await running.value
    #expect(result.exitCode == 130)
    #expect(result.output == payload)
    await supervisor.finish()
    try await Task.sleep(for: .seconds(1))
    #expect(!FileManager.default.fileExists(atPath: marker.path))
    #expect(!FileManager.default.fileExists(atPath: supervisor.directory.path))

    let late = try PrivilegedSupervisor()
    late.cancel()
    let refused = try await BrewRunner().run(late.command(shell: record.shellCommand, title: "运行测试", mutatesState: false), settings: settings)
    #expect(refused.exitCode == 130)
    #expect(refused.output.isEmpty)
    #expect(!FileManager.default.fileExists(atPath: marker.path))
    await late.finish()
  }
}
