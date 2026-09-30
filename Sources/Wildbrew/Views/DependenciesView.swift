import SwiftUI
import WildbrewCore

struct DependenciesView: View {
  @Bindable var model: AppModel
  @State private var selectedID = ""
  @State private var overwrite = false
  @State private var force = false
  var package: BrewPackage? { model.installed.first { $0.id == selectedID } }
  var body: some View {
    Form {
      PackagePicker(packages: model.installed, selection: $selectedID)
      if let package {
        LabeledContent("安装来源", value: package.installedOnRequest || package.kind == .cask ? "主动安装" : "依赖安装")
        LabeledContent("依赖", value: package.dependencies.joined(separator: ", "))
        HStack {
          Button("查看依赖树", systemImage: "point.3.connected.trianglepath.dotted") { model.enqueue(model.commands.dependencies(package.fullName)) }
          Button("查看反向依赖", systemImage: "arrow.turn.up.left") { model.enqueue(model.commands.uses(package.fullName)) }
        }
        if package.kind == .formula {
          LabeledContent("链接版本", value: package.raw["linked_keg"].display)
          Toggle("覆盖现有链接", isOn: $overwrite)
          Toggle("包含 keg-only", isOn: $force)
          HStack {
            Button("预览链接", systemImage: "eye") { link(package, preview: true) }
            Button("链接软件", systemImage: "link") { link(package, preview: false) }
            Button("预览取消链接", systemImage: "eye") { model.enqueue(model.commands.link(package.fullName, unlink: true, dryRun: true)) }
            Button("取消链接", systemImage: "link.badge.plus") { model.enqueue(model.commands.link(package.fullName, unlink: true)) }
          }
        }
      }
      HStack {
        Button("检查缺失依赖", systemImage: "stethoscope") { model.enqueue(model.commands.diagnostic("missing")) }
        Button("查看叶节点", systemImage: "leaf") { model.enqueue(model.commands.diagnostic("leaves")) }
      }
    }.formStyle(.grouped)
  }
  func link(_ package: BrewPackage, preview: Bool) { model.enqueue(model.commands.link(package.fullName, overwrite: overwrite, force: force, dryRun: preview)) }
}
