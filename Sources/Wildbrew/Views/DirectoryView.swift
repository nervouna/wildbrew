import SwiftUI

struct DirectoryView: View {
  @Bindable var model: AppModel
  let keys = ["--prefix", "--cellar", "--caskroom", "--cache", "--repository"]
  var body: some View {
    Grid(alignment: .leading) {
      ForEach(keys, id: \.self) { key in
        GridRow {
          Text(key).foregroundStyle(.secondary)
          Text(model.directories[key] ?? "").textSelection(.enabled)
          Button("打开目录", systemImage: "folder") { model.openDirectory(key) }
        }
      }
    }.padding()
  }
}
