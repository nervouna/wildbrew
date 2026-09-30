import SwiftUI
import WildbrewCore

struct UpdatesView: View {
  @Bindable var model: AppModel
  @State private var selection = Set<String>()
  func upgradeSelected() {
    for kind in PackageKind.allCases {
      let names = model.outdated.filter { $0.kind == kind && selection.contains($0.id) }.map(\.name)
      if !names.isEmpty { model.enqueue(model.commands.packageAction("upgrade", kind: kind, names: names, options: model.greedy && kind == .cask ? ["--greedy"] : [])) }
    }
  }
  var body: some View {
    VStack {
      HStack {
        Toggle("包含自动更新和 latest", isOn: $model.greedy)
        Spacer()
        Button("更新 Homebrew", systemImage: "arrow.triangle.2.circlepath") { model.enqueue(model.commands.update()) }
        Button("检查更新", systemImage: "arrow.clockwise") { model.enqueue(model.commands.outdated(greedy: model.greedy), .outdated) }
      }.padding()
      Table(model.outdated, selection: $selection) {
        TableColumn("软件", value: \.name)
        TableColumn("类型") { Text($0.kind.rawValue) }
        TableColumn("当前版本") { Text($0.installedVersions.joined(separator: ", ")) }
        TableColumn("目标版本", value: \.currentVersion)
        TableColumn("固定版本") { Text($0.pinned ? "是" : "否") }
      }
      HStack {
        Button("升级所选", systemImage: "arrow.up.circle", action: upgradeSelected).disabled(selection.isEmpty)
        Button("升级全部", systemImage: "arrow.up.circle.fill") { model.enqueue(model.commands.upgradeAll(greedy: model.greedy)) }
        Button("预览升级", systemImage: "eye") { model.enqueue(model.commands.upgradeAll(greedy: model.greedy, dryRun: true)) }
        Spacer()
      }.padding()
    }
  }
}
