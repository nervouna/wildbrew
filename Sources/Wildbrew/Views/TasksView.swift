import SwiftUI

struct TasksView: View {
  @Bindable var model: AppModel
  var body: some View {
    VSplitView {
      Table(model.tasks, selection: $model.selectedTask) {
        TableColumn("操作") { Text($0.command.title) }
        TableColumn("状态") { record in
          HStack {
            Text(record.status.rawValue)
            if record.status == .running {
              ProgressView().progressViewStyle(.linear).frame(width: 80)
                .accessibilityLabel(record.command.title)
            }
          }
        }
        TableColumn("时间") { Text($0.started, format: .dateTime.hour().minute().second()) }
        TableColumn("退出码") { Text($0.exitCode.map(String.init) ?? "") }
      }
      TaskConsoleView(model: model).frame(minHeight: 200)
    }.toolbar { Button("清除已结束任务", systemImage: "trash", action: model.clearCompleted) }
  }
}
