import Foundation

enum Module: String, CaseIterable, Identifiable {
  case discover = "发现", installed = "已安装", updates = "更新", services = "服务", cleanup = "清理", dependencies = "依赖", taps = "软件源", brewfile = "Brewfile", diagnostics = "诊断", advanced = "高级", tasks = "任务", settings = "设置"
  var id: String { rawValue }
  var symbol: String {
    switch self {
    case .discover: "square.grid.2x2"
    case .installed: "shippingbox"
    case .updates: "arrow.triangle.2.circlepath"
    case .services: "gearshape.2"
    case .cleanup: "trash"
    case .dependencies: "point.3.connected.trianglepath.dotted"
    case .taps: "externaldrive.connected.to.line.below"
    case .brewfile: "doc.text"
    case .diagnostics: "stethoscope"
    case .advanced: "wrench.and.screwdriver"
    case .tasks: "list.bullet.rectangle"
    case .settings: "slider.horizontal.3"
    }
  }
}
