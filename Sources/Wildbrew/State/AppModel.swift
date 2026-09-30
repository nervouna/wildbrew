import SwiftUI
import WildbrewCore

@Observable @MainActor final class AppModel {
  var preferences = AppPreferences.load()
  var installed: [BrewPackage] = []
  var catalog: [BrewPackage] = []
  var extraPackages: [BrewPackage] = []
  var outdated: [OutdatedPackage] = []
  var services: [BrewService] = []
  var taps: [BrewTap] = []
  var tasks: [TaskRecord] = []
  var selectedTask: UUID?
  var directories: [String: String] = [:]
  var vulnerabilities: VulnerabilityReport?
  var greedy = false
  var systemServices = false
  var loadingCatalog = false
  var brewfilePath = "" { didSet { if oldValue != brewfilePath { brewfileRevision += 1 } } }
  var brewfileText = "" { didSet { if oldValue != brewfileText { brewfileRevision += 1 } } }
  private(set) var brewfileRevision = 0
  private var savedBrewfilePath = ""
  private var savedBrewfileText = ""
  var brewfileDirty: Bool { brewfileText != savedBrewfileText }
  var packageDetails: [String: BrewPackage] = [:]
  @ObservationIgnored private var hasLaunched = false
  @ObservationIgnored private var active: Task<Void, Never>?
  @ObservationIgnored private var timer: Task<Void, Never>?
  var commands: CommandFactory { CommandFactory(brewPath: preferences.brew.brewPath) }
  var packages: [BrewPackage] {
    // Installed records contain pin and provenance fields absent from the public catalog.
    var merged = Dictionary(catalog.map { ($0.id, $0) }, uniquingKeysWith: { _, b in b })
    for package in extraPackages { merged[package.id] = package }
    for package in installed { merged[package.id] = package }
    return merged.values.sorted { $0.fullName.localizedStandardCompare($1.fullName) == .orderedAscending }
  }
  func launch() {
    guard !hasLaunched else { return }
    hasLaunched = true
    refresh()
    restartTimer()
    Task { await loadCatalog() }
  }
  func loadCatalog() async {
    guard !loadingCatalog else { return }
    loadingCatalog = true
    defer { loadingCatalog = false }
    do {
      let client = BrewClient(settings: preferences.brew)
      async let formulae = client.catalog(kind: .formula)
      async let casks = client.catalog(kind: .cask)
      catalog = try await formulae + casks
    } catch { recordError("读取目录", error) }
  }
  func refresh() {
    enqueue(commands.installed(), .installed)
    enqueue(commands.outdated(greedy: greedy), .outdated)
    refreshServices()
    enqueue(commands.tapInfo(), .taps)
    for flag in ["--prefix", "--cellar", "--caskroom", "--cache", "--repository"] {
      enqueue(commands.command([flag], title: "读取目录"), .directory(flag))
    }
  }
  func refreshServices() {
    if systemServices {
      // System scope uses the native administrator authentication prompt.
      enqueue(commands.services("info", system: true), .services)
    } else { enqueue(commands.services("info"), .services) }
  }
  func enqueue(_ command: BrewCommand, _ destination: ResultDestination = .log) {
    let record = TaskRecord(command: command, settings: preferences.brew, destination: destination)
    tasks.append(record)
    selectedTask = record.id
    pump()
  }
  func pump() {
    guard active == nil, let index = tasks.firstIndex(where: { $0.status == .queued }) else { return }
    let record = tasks[index]
    tasks[index].status = .running
    active = Task {
      do {
        var execution = record.command
        if execution.executable == "/usr/bin/sudo" {
          var privileged = execution
          privileged.executable = privileged.arguments.removeFirst()
          let rootRecord = TaskRecord(command: privileged, settings: record.settings, destination: record.destination)
          let script = "do shell script \"" + Self.appleScriptString(rootRecord.shellCommand) + "\" with administrator privileges"
          execution = BrewCommand(executable: "/usr/bin/osascript", arguments: ["-e", script], title: record.command.title, mutatesState: record.command.mutatesState)
        }
        let result = try await BrewRunner().run(execution, settings: record.settings) { output in
          await self.append(output.text, to: record.id)
        }
        if let index = self.tasks.firstIndex(where: { $0.id == record.id }) {
          self.tasks[index].exitCode = result.exitCode
          self.tasks[index].status = result.succeeded ? .succeeded : .failed
        }
        // Some diagnostic commands return useful structured results with a nonzero exit status.
        if result.succeeded || record.destination == .vulnerabilities {
          do { try self.consume(result.stdout, record.destination) }
          catch {
            self.append(error.localizedDescription + "\n", to: record.id)
            if let index = self.tasks.firstIndex(where: { $0.id == record.id }) { self.tasks[index].status = .failed }
          }
        }

      } catch {
        if let index = self.tasks.firstIndex(where: { $0.id == record.id }) {
          self.tasks[index].status = Task.isCancelled ? .cancelled : .failed
          self.tasks[index].output += error.localizedDescription + "\n"
        }
      }
      if record.command.mutatesState {
        self.packageDetails.removeAll()
        self.refresh()
      }
      self.active = nil
      self.pump()
    }
  }
  func append(_ text: String, to id: UUID) {
    if let index = tasks.firstIndex(where: { $0.id == id }) { tasks[index].output += text }
  }
  func consume(_ data: Data, _ destination: ResultDestination) throws {
    switch destination {
    case .installed:
      installed = try PackageParser.installed(data)
      packageDetails.removeAll()
      extraPackages.removeAll { $0.isInstalled }
    case .outdated: outdated = try OutdatedPackage.parse(data)
    case .services: services = try BrewService.parse(data)
    case .taps: taps = try BrewTap.parse(data)
    case .package(let id):
      if let package = try PackageParser.installed(data).first {
        packageDetails[id] = package
        extraPackages.removeAll { $0.id == package.id }
        extraPackages.append(package)
      }
    case .vulnerabilities: vulnerabilities = try VulnerabilityReport(data: data)
    case .directory(let key): directories[key] = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
    case .brewfile(let path, let revision):
      // A queued command must not replace edits or another file opened since submission.
      guard brewfilePath == path, brewfileRevision == revision else { return }
      try readBrewfile()
    case .log: break
    }
  }
  func cancel(_ id: UUID) {
    guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
    if tasks[index].status == .running { active?.cancel() }
    else if tasks[index].status == .queued { tasks[index].status = .cancelled; pump() }
  }
  func retry(_ record: TaskRecord) {
    var next = TaskRecord(command: record.command, settings: record.settings, destination: record.destination)
    next.status = .queued
    tasks.append(next)
    selectedTask = next.id
    pump()
  }
  func clearCompleted() { tasks.removeAll { $0.isFinished }; selectedTask = nil }
  func copy(_ text: String) { NSPasteboard.general.clearContents(); NSPasteboard.general.setString(text, forType: .string) }
  static func appleScriptString(_ text: String) -> String {
    text.replacing("\\", with: "\\\\").replacing("\"", with: "\\\"").replacing("\n", with: "\\n")
  }
  func handoff(_ record: TaskRecord) {
    if record.status == .running {
      let running = active
      cancel(record.id)
      Task {
        await running?.value
        if let finished = self.tasks.first(where: { $0.id == record.id }) { self.handoff(finished) }
      }
      return
    }
    let script = "tell application \"Terminal\"\nactivate\ndo script \"" + record.shellCommand.replacing("\\", with: "\\\\").replacing("\"", with: "\\\"").replacing("\n", with: "\\n") + "\"\nend tell"
    var error: NSDictionary?
    NSAppleScript(source: script)?.executeAndReturnError(&error)
    if let error { append(error.description + "\n", to: record.id); return }
    if let index = tasks.firstIndex(where: { $0.id == record.id }), tasks[index].status == .queued {
      tasks[index].status = .handedOff
    }
    pump()
  }
  func recordError(_ title: String, _ error: Error) {
    var record = TaskRecord(command: commands.command([], title: title), settings: preferences.brew, destination: .log)
    record.localFailure = true
    record.status = .failed; record.output = error.localizedDescription
    tasks.append(record); selectedTask = record.id
  }
  func savePreferences() {
    do { try preferences.save(); restartTimer() } catch { recordError("保存设置", error) }
  }
  func restartTimer() {
    timer?.cancel()
    let minutes = preferences.periodicMinutes
    guard minutes > 0 else { return }
    timer = Task {
      while !Task.isCancelled {
        do { try await Task.sleep(for: .seconds(minutes * 60)) } catch { return }
        enqueue(commands.outdated(greedy: greedy), .outdated)
      }
    }
  }
  func packageAction(_ action: String, _ packages: [BrewPackage], options: [String] = []) {
    for kind in PackageKind.allCases {
      let names = packages.filter { $0.kind == kind }.map(\.fullName)
      if !names.isEmpty { enqueue(commands.packageAction(action, kind: kind, names: names, options: options)) }
    }
  }
  func readPackage(_ package: BrewPackage) { enqueue(commands.info(package), .package(package.id)) }
  func readTapPackage(_ name: String, kind: PackageKind) {
    enqueue(commands.command(["info", "--json=v2", kind.flag, name], title: "读取软件"), .package(kind.rawValue + ":" + name))
  }
  func openDirectory(_ key: String) {
    if let path = directories[key], !path.isEmpty { NSWorkspace.shared.open(URL(fileURLWithPath: path)) }
  }
  func newBrewfile() { brewfilePath = ""; brewfileText = ""; savedBrewfileText = ""; savedBrewfilePath = "" }
  func openBrewfile() {
    let panel = NSOpenPanel(); panel.canChooseDirectories = false; panel.allowsMultipleSelection = false
    guard panel.runModal() == .OK, let url = panel.url else { return }
    brewfilePath = url.path
    do { try readBrewfile() } catch { recordError("打开 Brewfile", error) }
  }
  func readBrewfile() throws {
    let revision = brewfileRevision
    brewfileText = try String(contentsOfFile: brewfilePath, encoding: .utf8)
    savedBrewfileText = brewfileText
    savedBrewfilePath = brewfilePath
    // Reloads are not new editor changes; later queued results may still refresh this file.
    brewfileRevision = revision
  }
  @discardableResult func saveBrewfile() -> Bool {
    if brewfilePath.isEmpty {
      let panel = NSSavePanel(); panel.nameFieldStringValue = "Brewfile"
      guard panel.runModal() == .OK, let url = panel.url else { return false }
      brewfilePath = url.path
    }
    if brewfilePath == savedBrewfilePath && !brewfileDirty { return true }
    do { try brewfileText.write(toFile: brewfilePath, atomically: true, encoding: .utf8); savedBrewfileText = brewfileText; savedBrewfilePath = brewfilePath; return true }
    catch { recordError("保存 Brewfile", error); return false }
  }
  func bundle(_ action: String, names: [String] = [], kind: PackageKind? = nil, force: Bool = false, noUpgrade: Bool = false) {
    guard saveBrewfile() else { return }
    enqueue(commands.bundle(action, file: brewfilePath, names: names, kind: kind, force: force, noUpgrade: noUpgrade), ["dump", "add", "remove"].contains(action) ? .brewfile(path: brewfilePath, revision: brewfileRevision) : .log)
  }
  func exportBrewfile() {
    let panel = NSSavePanel(); panel.nameFieldStringValue = "Brewfile"
    guard panel.runModal() == .OK, let url = panel.url else { return }
    brewfilePath = url.path
    enqueue(commands.bundle("dump", file: url.path, force: true), .brewfile(path: url.path, revision: brewfileRevision))
  }
}
