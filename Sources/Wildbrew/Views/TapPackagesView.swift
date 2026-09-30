import SwiftUI
import WildbrewCore

struct TapPackagesView: View {
  @Bindable var model: AppModel
  let tap: BrewTap
  let search: String
  var body: some View {
    LazyVStack(alignment: .leading) {
      ForEach(tap.formulaNames.filter { search.isEmpty || $0.localizedStandardContains(search) }, id: \.self) { name in
        TapPackageRow(model: model, name: name, kind: .formula)
      }
      ForEach(tap.caskTokens.filter { search.isEmpty || $0.localizedStandardContains(search) }, id: \.self) { name in
        TapPackageRow(model: model, name: name, kind: .cask)
      }
    }
  }
}
