import Foundation

public struct BrewSettings: Codable, Sendable, Equatable {
  public var brewPath = "/opt/homebrew/bin/brew"
  public var workingDirectory = FileManager.default.homeDirectoryForCurrentUser.path
  public var appDirectory = "/Applications"
  public var caskOptions = ""
  public var language = ""
  public var cacheDirectory = ""
  public var autoUpdate = true
  public var autoCleanup = true
  public var additionalEnvironment: [String: String] = [:]
  public init() {}
  public func configured(_ command: BrewCommand) -> BrewCommand {
    var command = command
    let brewArguments =
      command.executable == "/usr/bin/sudo"
      ? Array(command.arguments.dropFirst()) : command.arguments
    if let action = brewArguments.first, ["install", "reinstall", "upgrade"].contains(action),
      !brewArguments.contains("--formula")
    {
      command.arguments.append("--appdir=" + appDirectory)
      if !language.isEmpty { command.arguments.append("--language=" + language) }
      command.arguments += caskOptions.split(whereSeparator: \.isWhitespace).map(String.init)
    }
    return command
  }
  public func environment(for command: BrewCommand) -> [String: String] {
    var values = additionalEnvironment
    let bin = URL(fileURLWithPath: brewPath).deletingLastPathComponent().path
    values["PATH"] =
      bin + ":/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:"
      + (ProcessInfo.processInfo.environment["PATH"] ?? "")
    if !command.mutatesState || !autoUpdate { values["HOMEBREW_NO_AUTO_UPDATE"] = "1" }
    if !autoCleanup { values["HOMEBREW_NO_INSTALL_CLEANUP"] = "1" }
    if command.mutatesState { values["HOMEBREW_NO_ASK"] = "1" }
    if !cacheDirectory.isEmpty { values["HOMEBREW_CACHE"] = cacheDirectory }
    values["HOMEBREW_NO_COLOR"] = "1"
    values["HOMEBREW_NO_EMOJI"] = "1"
    return values
  }
}
