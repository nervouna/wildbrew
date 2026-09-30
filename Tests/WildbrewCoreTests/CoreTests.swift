import Foundation
import Testing

@testable import WildbrewCore

@Test func decodeDistinctPackageShapes() throws {
  let data = Data(
    #"{"formulae":[{"name":"tool","full_name":"owner/tap/tool","versions":{"stable":"2"},"installed":[{"version":"1","installed_on_request":true}]}],"casks":[{"token":"app","name":["An App"],"version":"latest","installed":"latest","pinned":true,"auto_updates":true}]}"#
      .utf8)
  let packages = try PackageParser.installed(data)
  #expect(packages.count == 2)
  #expect(packages[0].id == "formula:owner/tap/tool")
  #expect(packages[0].installedOnRequest)
  #expect(packages[1].installedVersions == ["latest"])
  #expect(packages[1].pinned)
  let catalog = try PackageParser.catalog(
    Data(#"[{"token":"app","name":["An App"],"installed":null}]"#.utf8), kind: .cask)
  #expect(!catalog[0].isInstalled)
  let outdated = try OutdatedPackage.parse(
    Data(
      #"{"formulae":[],"casks":[{"name":"app","installed_versions":["1"],"current_version":"2"}]}"#
        .utf8))
  #expect(outdated.first?.kind == .cask)
}

@Test func preserveLiteralArgumentsAndReadIsolation() {
  let factory = CommandFactory(brewPath: "/tmp/brew path")
  let command = factory.bundle("install", file: "/tmp/Brewfile $(touch forbidden)")
  #expect(command.arguments.contains("--file=/tmp/Brewfile $(touch forbidden)"))
  var settings = BrewSettings()
  settings.appDirectory = "/tmp/My Applications"
  let install = settings.configured(factory.install(kind: .cask, names: ["app"]))
  #expect(install.arguments.contains("--appdir=/tmp/My Applications"))
  #expect(settings.environment(for: factory.installed())["HOMEBREW_NO_AUTO_UPDATE"] == "1")
  #expect(settings.environment(for: install)["HOMEBREW_NO_ASK"] == "1")
}

@Test func runnerSeparatesStreamsAndReportsExit() async throws {
  let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let script = directory.appending(path: "fixture.sh")
  try Data("#!/bin/sh\nprintf '%s' \"$1\"\nprintf 'warning' >&2\nexit 7\n".utf8).write(to: script)
  var settings = BrewSettings()
  settings.workingDirectory = directory.path
  let result = try await BrewRunner().run(
    BrewCommand(
      executable: "/bin/sh", arguments: [script.path, "$(touch impossible)"], title: "测试"),
    settings: settings)
  #expect(result.output == "$(touch impossible)")
  #expect(result.errorOutput == "warning")
  #expect(result.exitCode == 7)
  #expect(!FileManager.default.fileExists(atPath: directory.appending(path: "impossible").path))
}

@Test func cancellationStopsRunner() async throws {
  let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
  defer { try? FileManager.default.removeItem(at: directory) }
  let script = directory.appending(path: "fixture.sh")
  let marker = directory.appending(path: "marker")
  try Data("#!/bin/sh\n(sleep 1; echo persisted > marker) &\nwait\n".utf8).write(to: script)
  var settings = BrewSettings()
  settings.workingDirectory = directory.path
  let task = Task {
    try await BrewRunner().run(
      BrewCommand(executable: "/bin/sh", arguments: [script.path], title: "测试"), settings: settings)
  }
  try await Task.sleep(for: .milliseconds(150))
  task.cancel()
  do {
    _ = try await task.value
    Issue.record("Cancelled runner returned normally")
  } catch { #expect(error is CancellationError) }
  try await Task.sleep(for: .milliseconds(1200))
  #expect(!FileManager.default.fileExists(atPath: marker.path))
}
