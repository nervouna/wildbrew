import SwiftUI

struct TaskConsoleView: View {
  @Bindable var model: AppModel
  var record: TaskRecord? { model.tasks.first { $0.id == model.selectedTask } ?? model.tasks.last }
  var body: some View {
    VStack(alignment: .leading) {
      if let record {
        HStack {
          Text(record.command.title).bold()
          Text(record.status.rawValue).foregroundStyle(.secondary)
          if let code = record.exitCode { Text("\(code)").monospacedDigit() }
          Spacer()
          if !record.localFailure {
          Button("复制命令", systemImage: "doc.on.doc") { model.copy(record.shellCommand) }
          Button("在终端执行", systemImage: "terminal") { model.handoff(record) }
          if [.running, .queued].contains(record.status) { Button("取消任务", systemImage: "xmark.circle") { model.cancel(record.id) } }
          if record.isFinished { Button("重试任务", systemImage: "arrow.clockwise") { model.retry(record) } }
          }
        }
        ScrollView([.horizontal, .vertical]) {
          Text(record.output.isEmpty ? record.shellCommand : record.output).font(.system(.body, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
        }
      } else { ContentUnavailableView("无任务", systemImage: "list.bullet.rectangle") }
    }.padding()
  }
}
