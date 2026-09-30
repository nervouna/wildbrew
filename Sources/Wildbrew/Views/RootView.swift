import SwiftUI

struct RootView: View {
  @Bindable var model: AppModel
  @State private var module: Module? = .discover
  var body: some View {
    NavigationSplitView {
      List(Module.allCases, selection: $module) { item in Label(item.rawValue, systemImage: item.symbol).tag(item) }
        .navigationTitle("Wildbrew").navigationSplitViewColumnWidth(min: 160, ideal: 190)
    } detail: {
      VStack(spacing: 0) {
        Group {
          switch module ?? .discover {
          case .discover: PackagesView(model: model, installedOnly: false)
          case .installed: PackagesView(model: model, installedOnly: true)
          case .updates: UpdatesView(model: model)
          case .services: ServicesView(model: model)
          case .cleanup: CleanupView(model: model)
          case .dependencies: DependenciesView(model: model)
          case .taps: TapsView(model: model)
          case .brewfile: BrewfileView(model: model)
          case .diagnostics: DiagnosticsView(model: model)
          case .advanced: AdvancedView(model: model)
          case .tasks: TasksView(model: model)
          case .settings: SettingsView(model: model)
          }
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        if module != .tasks { Divider(); TaskConsoleView(model: model).frame(height: 170) }
      }.navigationTitle((module ?? .discover).rawValue)
        .toolbar { Button("刷新状态", systemImage: "arrow.clockwise", action: model.refresh) }
    }
  }
}
