import SwiftUI
import WildbrewCore

struct TapPackageRow: View {
  @Bindable var model: AppModel
  let name: String
  let kind: PackageKind
  var body: some View {
    HStack {
      Label(name, systemImage: kind == .formula ? "shippingbox" : "app")
      Spacer()
      Button("读取软件", systemImage: "doc.text") { model.readTapPackage(name, kind: kind) }
      Button("安装软件", systemImage: "arrow.down.circle") { model.enqueue(model.commands.install(kind: kind, names: [name])) }
    }
  }
}
