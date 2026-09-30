import SwiftUI
import WildbrewCore

struct PackageDetailView: View {
  @Bindable var model: AppModel
  let package: BrewPackage
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        Label(package.displayName, systemImage: package.kind == .formula ? "shippingbox" : "app").font(.title2).bold()
        Text(package.summary).textSelection(.enabled)
        HStack {
          Button(package.isInstalled ? "升级软件" : "安装软件", systemImage: "arrow.down.circle") { model.packageAction(package.isInstalled ? "upgrade" : "install", [package]) }
          Menu("管理软件", systemImage: "ellipsis.circle") {
            Button("重装软件", systemImage: "arrow.clockwise") { model.packageAction("reinstall", [package]) }
            Button("卸载软件", systemImage: "trash") { model.packageAction("uninstall", [package]) }
            if package.kind == .cask {
              Button("卸载并移除数据", systemImage: "trash.slash") { model.enqueue(model.commands.uninstall(kind: .cask, names: [package.fullName], zap: true)) }
            }
            Button(package.pinned ? "取消固定" : "固定版本", systemImage: "pin") { model.enqueue(model.commands.command([package.pinned ? "unpin" : "pin", package.kind.flag, package.fullName], title: package.pinned ? "取消固定" : "固定版本", mutatesState: true)) }
          }
        }
        LabeledContent("软件名", value: package.fullName)
        LabeledContent("类型", value: package.kind.rawValue)
        LabeledContent("版本", value: package.version)
        LabeledContent("已安装", value: package.installedVersions.joined(separator: ", "))
        LabeledContent("软件源", value: package.tap)
        LabeledContent("许可证", value: package.license)
        LabeledContent("固定版本", value: package.pinned ? "是" : "否")
        LabeledContent("安装来源", value: package.isInstalled ? (package.installedOnRequest || package.kind == .cask ? "主动安装" : "依赖安装") : "未安装")
        LabeledContent("链接版本", value: package.raw["linked_keg"].display)
        LabeledContent("依赖", value: package.dependencies.joined(separator: ", "))
        if let url = URL(string: package.homepage), !package.homepage.isEmpty { Link("打开主页", destination: url) }
        if let source = package.raw["urls"]["stable"]["url"].string ?? package.raw["url"].string, let url = URL(string: source) { Link("打开源码", destination: url) }
        HStack {
          Button("读取详情", systemImage: "arrow.clockwise") { model.readPackage(package) }
          Button("查看文件", systemImage: "doc.text") { model.enqueue(model.commands.files(package)) }
        }
        Button("查看占用", systemImage: "internaldrive") { model.enqueue(model.commands.command(["info", "--sizes", package.kind.flag, package.fullName], title: "查看占用")) }
        Button("打开配方源码", systemImage: "curlybraces") { model.enqueue(model.commands.command(["info", "--github", package.kind.flag, package.fullName], title: "打开配方源码")) }
        Button("查看安装位置", systemImage: "folder") { model.enqueue(model.commands.command([package.kind == .formula ? "--prefix" : "--caskroom", package.fullName], title: "查看安装位置")) }
        DisclosureGroup("元数据") { Text(package.raw.pretty).font(.system(.body, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
      }.padding()
    }
  }
}
