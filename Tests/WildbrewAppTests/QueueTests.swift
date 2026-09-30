import Foundation
import Testing
import WildbrewCore
@testable import Wildbrew

struct QueueTests {
  @Test @MainActor func serialQueueCancellationAndSnapshots() async throws {
    let model = AppModel()
    model.preferences.brew.workingDirectory = "/private/tmp"
    model.preferences.brew.language = "en"
    let first = BrewCommand(executable: "/bin/sh", arguments: ["-c", "printf started; sleep 20; printf finished"], title: "运行测试")
    let second = BrewCommand(executable: "/bin/sh", arguments: ["-c", "printf second"], title: "运行测试")
    model.enqueue(first)
    model.enqueue(second)
    let firstID = model.tasks[0].id
    model.preferences.brew.language = "zh"
    let deadline = Date.now.addingTimeInterval(8)
    while model.tasks[0].output.isEmpty && Date.now < deadline { try await Task.sleep(for: .milliseconds(30)) }
    #expect(model.tasks[0].status == .running)
    #expect(model.tasks[1].status == .queued)
    #expect(model.tasks[1].settings.language == "en")
    model.cancel(firstID)
    while !model.tasks[1].isFinished && Date.now < deadline { try await Task.sleep(for: .milliseconds(30)) }
    #expect(model.tasks[0].status == .cancelled)
    #expect(model.tasks[1].status == .succeeded)
    #expect(model.tasks[1].output == "second")
    #expect(!model.tasks[0].output.contains("finished"))
  }
}
