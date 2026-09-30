import SwiftUI

struct ServicesView: View {
  @Bindable var model: AppModel
  @State private var selection = Set<String>()
  var body: some View {
    VStack {
      HStack {
        Toggle("系统服务", isOn: $model.systemServices).onChange(of: model.systemServices) { model.refreshServices() }
        Spacer()
        Button("读取服务", systemImage: "arrow.clockwise", action: model.refreshServices)
        Button("清理服务", systemImage: "trash") { model.enqueue(model.commands.services("cleanup", system: model.systemServices)) }
      }.padding()
      Table(model.services, selection: $selection) {
        TableColumn("服务", value: \.name)
        TableColumn("运行") { Text($0.raw["running"].bool ? "运行中" : "已停止") }
        TableColumn("登录注册") { Text($0.raw["registered"].bool ? "已注册" : "未注册") }
        TableColumn("状态", value: \.status)
        TableColumn("用户", value: \.user)
      }
      HStack {
        Button("启动服务", systemImage: "play") { act("start") }
        Button("停止服务", systemImage: "stop") { act("stop") }
        Button("重启服务", systemImage: "arrow.clockwise") { act("restart") }
        Button("运行服务", systemImage: "play.circle") { act("run") }
        Button("终止服务", systemImage: "xmark.circle") { act("kill") }
        Button("读取详情", systemImage: "doc.text") { act("info") }
        Spacer()
      }.disabled(selection.isEmpty).padding()
      if let service = model.services.first(where: { selection.contains($0.id) }) {
        ScrollView { Text(service.raw.pretty).textSelection(.enabled).font(.system(.body, design: .monospaced)).frame(maxWidth: .infinity, alignment: .leading) }.frame(maxHeight: 160).padding(.horizontal)
      }
    }
  }
  func act(_ action: String) { model.enqueue(model.commands.services(action, names: selection.sorted(), system: model.systemServices)) }
}
