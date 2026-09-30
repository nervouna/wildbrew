import SwiftUI
import WildbrewCore

struct PackagesView: View {
  @Bindable var model: AppModel
  let installedOnly: Bool
  @State private var search = ""
  @State private var kind = "all"
  @State private var selection = Set<String>()
  @State private var focusedPackage: String?
  var rows: [BrewPackage] {
    (installedOnly ? model.installed : model.packages).filter {
      (kind == "all" || $0.kind.rawValue == kind) && (search.isEmpty || $0.fullName.localizedStandardContains(search) || $0.summary.localizedStandardContains(search))
    }
  }
  var selected: [BrewPackage] { rows.filter { selection.contains($0.id) } }
  var detail: BrewPackage? {
    let id = focusedPackage ?? selection.sorted().first
    guard let id else { return nil }
    return model.packageDetails[id] ?? rows.first { $0.id == id }
  }
  var body: some View {
    HStack(spacing: 0) {
      VStack {
        HStack {
          TextField("搜索软件", text: $search)
          Picker("类型", selection: $kind) { Text("全部").tag("all"); Text("Formula").tag("formula"); Text("Cask").tag("cask") }.frame(width: 170)
          if model.loadingCatalog { ProgressView().controlSize(.small) }
        }.padding([.horizontal, .top])
        Table(rows, selection: $selection) {
          TableColumn("软件", value: \.fullName)
          TableColumn("版本", value: \.version).width(min: 70, ideal: 95)
          TableColumn("安装") { Text($0.installedVersions.joined(separator: ", ")) }.width(min: 70, ideal: 95)
          TableColumn("类型") { Text($0.kind.rawValue) }.width(65)
          TableColumn("描述", value: \.summary)
        }.frame(maxHeight: .infinity).onChange(of: selection) { focusedPackage = nil }
        HStack {
          Button("安装所选", systemImage: "arrow.down.circle") { model.packageAction("install", selected) }.disabled(selected.isEmpty)
          Button("升级所选", systemImage: "arrow.up.circle") { model.packageAction("upgrade", selected) }.disabled(selected.isEmpty)
          if installedOnly { Button("卸载所选", systemImage: "trash") { model.packageAction("uninstall", selected) }.disabled(selected.isEmpty) }
          Spacer(); Text("\(rows.count)").foregroundStyle(.secondary)
        }.padding()
      }.frame(minWidth: 480, maxWidth: .infinity, maxHeight: .infinity)
      Divider()
      if let detail { PackageDetailView(model: model, package: detail).frame(width: 300).frame(maxHeight: .infinity) }
      else { ContentUnavailableView("未选择软件", systemImage: "shippingbox").frame(width: 300).frame(maxHeight: .infinity) }
    }.frame(maxWidth: .infinity, maxHeight: .infinity).toolbar {
      Button("读取目录", systemImage: "square.grid.2x2") { Task { await model.loadCatalog() } }
      Button("查看占用", systemImage: "internaldrive") { model.enqueue(model.commands.sizes()) }
    }
  }
}
