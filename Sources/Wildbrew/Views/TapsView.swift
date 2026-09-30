import SwiftUI
import WildbrewCore

struct TapsView: View {
  @Bindable var model: AppModel
  @State private var selection: String?
  @State private var name = ""
  @State private var remote = ""
  @State private var target = ""
  @State private var trustType = "tap"
  @State private var search = ""
  var tap: BrewTap? { model.taps.first { $0.id == selection } }
  var body: some View {
    HSplitView {
      VStack {
        Table(model.taps, selection: $selection) {
          TableColumn("软件源", value: \.name)
          TableColumn("远程地址", value: \.remote)
        }
        Form {
          TextField("软件源名称", text: $name)
          TextField("自定义远程地址", text: $remote)
          HStack {
            Button("添加软件源", systemImage: "plus") { model.enqueue(model.commands.tap(name, remote: remote.isEmpty ? nil : remote)) }.disabled(name.isEmpty)
            Button("移除软件源", systemImage: "minus") { if let tap { model.enqueue(model.commands.untap(tap.name)) } }.disabled(tap == nil)
            Button("读取软件源", systemImage: "arrow.clockwise") { model.enqueue(model.commands.tapInfo(), .taps) }
          }
        }.padding()
      }.frame(minWidth: 400)
      ScrollView {
        VStack(alignment: .leading) {
          if let tap {
            Text(tap.name).font(.title2).bold()
            Text(tap.remote).textSelection(.enabled)
            TextField("搜索软件源内软件", text: $search)
            TapPackagesView(model: model, tap: tap, search: search)
            DisclosureGroup("元数据") { Text(tap.raw.pretty).textSelection(.enabled).font(.system(.body, design: .monospaced)) }
          }
          Divider()
          Picker("信任类型", selection: $trustType) {
            Text("Tap").tag("tap"); Text("Formula").tag("formula"); Text("Cask").tag("cask"); Text("Command").tag("command")
          }
          TextField("信任目标", text: $target)
          HStack {
            Button("信任目标", systemImage: "checkmark.shield") { trust(false) }
            Button("取消信任", systemImage: "shield.slash") { trust(true) }
          }.disabled(target.isEmpty && tap == nil)
          Button("读取信任记录", systemImage: "doc.text") { model.enqueue(model.commands.trust()) }
        }.padding()
      }.frame(minWidth: 320)
    }
  }
  func trust(_ remove: Bool) {
    let value = target.isEmpty ? (tap?.name ?? "") : target
    model.enqueue(model.commands.trust([value], type: trustType, remove: remove))
  }
}
