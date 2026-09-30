import SwiftUI

@main struct WildbrewApp: App {
  @State private var model = AppModel()
  var body: some Scene {
    WindowGroup { RootView(model: model).frame(minWidth: 1000, minHeight: 700).task { model.launch() } }
    Settings { SettingsView(model: model).frame(width: 640, height: 650) }
  }
}
