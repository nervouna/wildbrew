import SwiftUI
import WildbrewCore

struct BrewfileView: View {
  @Bindable var model: AppModel
  @State private var names = ""
  @State private var kind = "all"
  @State private var noUpgrade = false
  var selectedKind: PackageKind? { PackageKind(rawValue: kind) }
  var body: some View {
    VStack {
      HStack {
        Button("新建 Brewfile", systemImage: "doc.badge.plus", action: model.newBrewfile)
        Button("打开 Brewfile", systemImage: "folder", action: model.openBrewfile)
        Button("保存 Brewfile", systemImage: "square.and.arrow.down") { model.saveBrewfile() }
        Button("导出环境", systemImage: "square.and.arrow.up", action: model.exportBrewfile)
        Spacer()
      }.padding()
      HStack { Text(model.brewfilePath.isEmpty ? "Brewfile" : model.brewfilePath).textSelection(.enabled); if model.brewfileDirty { Image(systemName: "circle.fill").accessibilityLabel("未保存") }; Spacer() }.padding(.horizontal)
      TextEditor(text: $model.brewfileText).font(.system(.body, design: .monospaced)).padding(.horizontal)
      HStack {
        Picker("类型", selection: $kind) {
          Text("全部").tag("all"); Text("Formula").tag("formula"); Text("Cask").tag("cask")
        }.frame(width: 170)
        TextField("软件名，以空格分隔", text: $names)
        Button("添加软件", systemImage: "plus") { model.bundle("add", names: tokens, kind: selectedKind) }.disabled(tokens.isEmpty)
        Button("移除软件", systemImage: "minus") { model.bundle("remove", names: tokens, kind: selectedKind) }.disabled(tokens.isEmpty)
      }.padding(.horizontal)
      HStack {
        Button("读取清单", systemImage: "list.bullet") { list(kind == "all" ? "all" : kind) }
        Menu("读取其他类型", systemImage: "list.bullet.rectangle") {
          ForEach(["tap", "mas", "vscode", "go", "cargo", "uv", "flatpak", "winget", "krew", "npm"], id: \.self) { type in
            Button("读取 \(type)") { list(type) }
          }
        }
        Button("检查环境", systemImage: "checkmark.circle") { model.bundle("check") }
        Spacer()
      }.padding(.horizontal)
      HStack {
        Toggle("保持已安装版本", isOn: $noUpgrade)
        Button("安装环境", systemImage: "arrow.down.circle") { model.bundle("install", noUpgrade: noUpgrade) }
        Button("预览环境清理", systemImage: "eye") { model.bundle("cleanup") }
        Button("清理环境", systemImage: "trash") { model.bundle("cleanup", force: true) }
      }.padding()
    }
  }
  var tokens: [String] { names.split(whereSeparator: \.isWhitespace).map(String.init) }
  func list(_ type: String) {
    guard model.saveBrewfile() else { return }
    model.enqueue(model.commands.command(["bundle", "list", "--file=" + model.brewfilePath, "--" + type], title: "读取清单"))
  }
}
