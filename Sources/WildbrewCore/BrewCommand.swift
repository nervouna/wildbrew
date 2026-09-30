import Foundation

public struct BrewCommand: Sendable, Equatable {
  public var executable: String
  public var arguments: [String]
  public var title: String
  public var mutatesState: Bool
  public init(executable: String, arguments: [String], title: String, mutatesState: Bool = false) {
    self.executable = executable
    self.arguments = arguments
    self.title = title
    self.mutatesState = mutatesState
  }
}
public struct CommandFactory: Sendable {
  public var brewPath: String
  public init(brewPath: String = "/opt/homebrew/bin/brew") { self.brewPath = brewPath }
  public func command(_ arguments: [String], title: String, mutatesState: Bool = false)
    -> BrewCommand
  { .init(executable: brewPath, arguments: arguments, title: title, mutatesState: mutatesState) }
  public func installed() -> BrewCommand {
    command(["info", "--json=v2", "--installed"], title: "读取软件")
  }
  public func info(_ package: BrewPackage) -> BrewCommand {
    command(["info", "--json=v2", package.kind.flag, package.fullName], title: "读取软件")
  }
  public func outdated(greedy: Bool = false) -> BrewCommand {
    command(["outdated", "--json=v2"] + (greedy ? ["--greedy"] : []), title: "检查更新")
  }
  public func update() -> BrewCommand {
    command(["update"], title: "更新 Homebrew", mutatesState: true)
  }
  public func packageAction(
    _ action: String, kind: PackageKind, names: [String], options: [String] = []
  ) -> BrewCommand {
    command(
      [action, kind.flag] + options + names,
      title: [
        "install": "安装", "uninstall": "卸载", "upgrade": "升级", "reinstall": "重装", "pin": "固定版本",
        "unpin": "取消固定",
      ][action] ?? action, mutatesState: !options.contains("--dry-run"))
  }
  public func install(
    kind: PackageKind, names: [String], head: Bool = false, source: Bool = false,
    dryRun: Bool = false
  ) -> BrewCommand {
    packageAction(
      "install", kind: kind, names: names,
      options: (head ? ["--HEAD"] : []) + (source ? ["--build-from-source"] : [])
        + (dryRun ? ["--dry-run"] : []))
  }
  public func upgradeAll(greedy: Bool = false, dryRun: Bool = false) -> BrewCommand {
    command(
      ["upgrade"] + (greedy ? ["--greedy"] : []) + (dryRun ? ["--dry-run"] : []), title: "升级软件",
      mutatesState: !dryRun)
  }
  public func uninstall(kind: PackageKind, names: [String], zap: Bool = false) -> BrewCommand {
    packageAction(
      "uninstall", kind: kind, names: names, options: zap && kind == .cask ? ["--zap"] : [])
  }
  public func services(_ action: String = "list", names: [String] = [], system: Bool = false)
    -> BrewCommand
  {
    var result = command(
      ["services", action] + (action == "list" || action == "info" ? ["--json"] : [])
        + (action == "info" && names.isEmpty ? ["--all"] : names),
      title: [
        "start": "启动服务", "stop": "停止服务", "restart": "重启服务", "run": "运行服务", "kill": "终止服务",
        "cleanup": "清理服务",
      ][action] ?? "读取服务", mutatesState: !["list", "info"].contains(action))
    if system {
      result.arguments = [brewPath] + result.arguments
      result.executable = "/usr/bin/sudo"
    }
    return result
  }
  public func cleanup(dryRun: Bool = true, names: [String] = []) -> BrewCommand {
    command(
      ["cleanup"] + (dryRun ? ["--dry-run"] : []) + names, title: dryRun ? "预览清理" : "清理缓存",
      mutatesState: !dryRun)
  }
  public func autoremove(dryRun: Bool = true) -> BrewCommand {
    command(
      ["autoremove"] + (dryRun ? ["--dry-run"] : []), title: dryRun ? "预览依赖" : "移除依赖",
      mutatesState: !dryRun)
  }
  public func dependencies(_ name: String, tree: Bool = true) -> BrewCommand {
    command(["deps"] + (tree ? ["--tree"] : []) + [name], title: "查看依赖")
  }
  public func uses(_ name: String) -> BrewCommand {
    command(["uses", "--installed", "--recursive", name], title: "查看引用")
  }
  public func files(_ package: BrewPackage) -> BrewCommand {
    command(["list", package.kind.flag, package.fullName], title: "查看文件")
  }
  public func tapInfo() -> BrewCommand {
    command(["tap-info", "--installed", "--json=v1"], title: "读取软件源")
  }
  public func tap(_ name: String, remote: String? = nil) -> BrewCommand {
    command(["tap", name] + (remote.map { [$0] } ?? []), title: "添加软件源", mutatesState: true)
  }
  public func untap(_ name: String) -> BrewCommand {
    command(["untap", name], title: "移除软件源", mutatesState: true)
  }
  public func trust(_ targets: [String] = [], type: String? = nil, remove: Bool = false)
    -> BrewCommand
  {
    command(
      [remove ? "untrust" : "trust"] + (type.map { ["--" + $0] } ?? [])
        + (targets.isEmpty && !remove ? ["--json=v1"] : targets), title: remove ? "取消信任" : "信任软件",
      mutatesState: !targets.isEmpty)
  }
  public func bundle(
    _ action: String, file: String, names: [String] = [], kind: PackageKind? = nil,
    force: Bool = false, noUpgrade: Bool = false
  ) -> BrewCommand {
    command(
      ["bundle", action, "--file=" + file] + (kind.map { [$0.flag] } ?? [])
        + (force ? ["--force"] : []) + (noUpgrade ? ["--no-upgrade"] : []) + names,
      title: [
        "dump": "导出环境", "install": "安装环境", "check": "检查环境", "list": "读取清单", "add": "添加软件",
        "remove": "移除软件", "cleanup": "清理环境",
      ][action] ?? action,
      mutatesState: ["dump", "install", "add", "remove"].contains(action)
        || (action == "cleanup" && force))
  }
  public func sizes() -> BrewCommand { command(["info", "--sizes", "--installed"], title: "查看占用") }
  public func diagnostic(_ action: String) -> BrewCommand {
    command(
      [action],
      title: [
        "doctor": "检查环境", "config": "读取配置", "missing": "检查依赖", "linkage": "检查链接", "leaves": "查看叶节点",
      ][action] ?? action)
  }
  public func vulnerabilities(
    names: [String] = [], severity: String? = nil, fixesOnly: Bool = false
  ) -> BrewCommand {
    command(
      ["vulns", "--json", "--list-skipped"] + (severity.map { ["--severity=" + $0] } ?? [])
        + (fixesOnly ? ["--fix-available"] : []) + names, title: "检查漏洞")
  }
  public func versionInstall(_ name: String, version: String) -> BrewCommand {
    command(["version-install", name, version], title: "安装历史版本", mutatesState: true)
  }
  public func fetch(_ package: BrewPackage) -> BrewCommand {
    command(["fetch", package.kind.flag, package.fullName], title: "下载软件", mutatesState: true)
  }
  public func link(
    _ name: String, unlink: Bool = false, overwrite: Bool = false, force: Bool = false,
    dryRun: Bool = false
  ) -> BrewCommand {
    command(
      [unlink ? "unlink" : "link"] + (overwrite ? ["--overwrite"] : []) + (force ? ["--force"] : [])
        + (dryRun ? ["--dry-run"] : []) + [name], title: unlink ? "取消链接" : "链接软件",
      mutatesState: !dryRun)
  }
  public func postinstall(_ name: String) -> BrewCommand {
    command(["postinstall", name], title: "执行安装后步骤", mutatesState: true)
  }
  public func analytics(enabled: Bool? = nil) -> BrewCommand {
    command(
      ["analytics"] + (enabled.map { [$0 ? "on" : "off"] } ?? ["state"]),
      title: enabled == nil ? "读取统计" : "设置统计", mutatesState: enabled != nil)
  }
}
