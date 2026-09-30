import Foundation
import WildbrewCore

struct TaskRecord: Identifiable {
  enum Status: String { case queued = "等待", running = "运行", succeeded = "完成", failed = "失败", cancelled = "已取消", handedOff = "终端已接收" }
  let id = UUID()
  let command: BrewCommand
  let settings: BrewSettings
  let destination: ResultDestination
  let started = Date.now
  var status = Status.queued
  var output = ""
  var exitCode: Int?
  var localFailure = false
  var isFinished: Bool { ![.queued, .running].contains(status) }
  var shellCommand: String {
    let configured = settings.configured(command)
    let environment = settings.environment(for: configured).sorted { $0.key < $1.key }
      .map { Self.quote($0.key + "=" + $0.value) }.joined(separator: " ")
    return "cd " + Self.quote(settings.workingDirectory) + " && /usr/bin/env " + environment + " "
      + ([configured.executable] + configured.arguments).map(Self.quote).joined(separator: " ")
  }
  static func quote(_ value: String) -> String { "'" + value.replacing("'", with: "'\\''") + "'" }
}
