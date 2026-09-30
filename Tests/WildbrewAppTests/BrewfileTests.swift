import Foundation
import Testing
import WildbrewCore
@testable import Wildbrew

struct BrewfileTests {
  @Test @MainActor func queuedBrewfileResultsPreserveEditor() async throws {
    let directory = URL.temporaryDirectory.appending(path: "wildbrew-editor-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    for scenario in 0..<3 {
      let original = directory.appending(path: "Brewfile-\(scenario)")
      let switched = directory.appending(path: "Other-\(scenario)")
      try "before".write(to: original, atomically: true, encoding: .utf8)
      try "other".write(to: switched, atomically: true, encoding: .utf8)
      let model = AppModel()
      model.preferences.brew.workingDirectory = directory.path
      model.brewfilePath = original.path
      try model.readBrewfile()
      let command = BrewCommand(executable: "/bin/sh", arguments: ["-c", "printf started; sleep 0.25; printf after > \"$1\"", "sh", original.path], title: "运行测试")
      model.enqueue(command, .brewfile(path: original.path, revision: model.brewfileRevision))
      let deadline = Date.now.addingTimeInterval(5)
      while model.tasks[0].output.isEmpty && Date.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
      #expect(model.tasks[0].status == .running)
      if scenario == 0 { model.brewfileText = "new edit" }
      if scenario == 1 {
        model.brewfilePath = switched.path
        try model.readBrewfile()
        try "external".write(to: switched, atomically: true, encoding: .utf8)
      }
      while !model.tasks[0].isFinished && Date.now < deadline { try await Task.sleep(for: .milliseconds(10)) }
      #expect(model.tasks[0].status == .succeeded)
      switch scenario {
      case 0:
        #expect(model.brewfileText == "new edit")
        #expect(model.brewfileDirty)
      case 1:
        #expect(model.brewfilePath == switched.path)
        #expect(model.brewfileText == "other")
        #expect(!model.brewfileDirty)
        // Reading/checking an unchanged editor must not rewrite external file changes.
        #expect(model.saveBrewfile())
        #expect(try String(contentsOf: switched, encoding: .utf8) == "external")
      default:
        #expect(model.brewfileText == "after")
        #expect(!model.brewfileDirty)
      }
    }
  }
}
