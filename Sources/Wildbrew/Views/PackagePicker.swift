import SwiftUI
import WildbrewCore

struct PackagePicker: View {
  let packages: [BrewPackage]
  @Binding var selection: String
  var body: some View {
    Picker("软件", selection: $selection) {
      Text("未选择").tag("")
      ForEach(packages) { Text($0.fullName).tag($0.id) }
    }.labelsHidden()
  }
}
