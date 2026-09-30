import SwiftUI
import WildbrewCore

struct AdvancedView: View {
  @Bindable var model: AppModel
  @State private var name = ""
  @State private var kind = PackageKind.formula
  @State private var version = ""
  @State private var head = false
  @State private var source = false
  @State private var overwrite = false
  @State private var force = false
  var body: some View {
    Form {
      TextField("软件名", text: $name)
      Picker("类型", selection: $kind) { ForEach(PackageKind.allCases, id: \.self) { Text($0.rawValue).tag($0) } }
      HStack {
        Button("读取详情", systemImage: "doc.text") { model.readTapPackage(name, kind: kind) }
        Button("下载软件", systemImage: "arrow.down.to.line") { command(["fetch", kind.flag, name], title: "下载软件", write: true) }
      }.disabled(name.isEmpty)
      if kind == .formula {
        TextField("历史版本", text: $version)
        HStack {
          Button("读取版本历史", systemImage: "clock.arrow.circlepath") { command(["log", "--formula", "--patch", "--max-count=20", name], title: "读取版本历史") }.disabled(name.isEmpty)
          Button("安装历史版本", systemImage: "arrow.down.circle") { model.enqueue(model.commands.versionInstall(name, version: version)) }.disabled(name.isEmpty || version.isEmpty)
        }
        Toggle("安装 HEAD", isOn: $head)
        Toggle("从源码构建", isOn: $source)
        Button("安装软件", systemImage: "arrow.down.circle") { model.enqueue(model.commands.install(kind: kind, names: [name], head: head, source: source)) }.disabled(name.isEmpty)
        Toggle("覆盖现有链接", isOn: $overwrite)
        Toggle("包含 keg-only", isOn: $force)
        HStack {
          Button("预览链接", systemImage: "eye") { link(true) }
          Button("链接软件", systemImage: "link") { link(false) }
          Button("取消链接", systemImage: "link.badge.plus") { model.enqueue(model.commands.link(name, unlink: true)) }
          Button("执行安装后步骤", systemImage: "gearshape") { model.enqueue(model.commands.postinstall(name)) }
        }.disabled(name.isEmpty)
      } else {
        Button("安装软件", systemImage: "arrow.down.circle") { model.enqueue(model.commands.install(kind: kind, names: [name])) }.disabled(name.isEmpty)
      }
    }.formStyle(.grouped)
  }
  func command(_ arguments: [String], title: String, write: Bool = false) { model.enqueue(model.commands.command(arguments, title: title, mutatesState: write)) }
  func link(_ preview: Bool) { model.enqueue(model.commands.link(name, overwrite: overwrite, force: force, dryRun: preview)) }
}
