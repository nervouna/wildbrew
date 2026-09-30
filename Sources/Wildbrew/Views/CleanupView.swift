import SwiftUI
import WildbrewCore

struct CleanupView: View {
  @Bindable var model: AppModel
  @State private var selection = Set<String>()
  @State private var all = true
  var body: some View {
    VStack {
      HStack {
        Toggle("全部软件", isOn: $all)
        TextField("缓存保留天数", value: $model.preferences.pruneDays, format: .number).frame(width: 130)
        Spacer()
        Button("读取占用", systemImage: "internaldrive") { model.enqueue(model.commands.sizes()) }
      }.padding()
      Table(model.installed, selection: $selection) {
        TableColumn("软件", value: \.fullName)
        TableColumn("类型") { Text($0.kind.rawValue) }
        TableColumn("版本") { Text($0.installedVersions.joined(separator: ", ")) }
      }.disabled(all)
      HStack {
        Button("预览清理", systemImage: "eye") { cleanup(true) }
        Button("清理缓存和旧版本", systemImage: "trash") { cleanup(false) }
        Button("预览多余依赖", systemImage: "eye") { model.enqueue(model.commands.autoremove()) }
        Button("移除多余依赖", systemImage: "minus.circle") { model.enqueue(model.commands.autoremove(dryRun: false)) }
        Spacer()
      }.padding()
      DirectoryView(model: model)
    }
  }
  func cleanup(_ preview: Bool) {
    let names = all ? [] : model.installed.filter { selection.contains($0.id) }.map(\.fullName)
    if !all && names.isEmpty { return }
    let base = model.commands.cleanup(dryRun: preview, names: names)
    var command = base
    command.arguments.insert("--prune=\(model.preferences.pruneDays)", at: 1)
    model.enqueue(command)
  }
}
