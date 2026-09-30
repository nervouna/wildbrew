import SwiftUI

struct SettingsView: View {
  @Bindable var model: AppModel
  var body: some View {
    Form {
      Section("Homebrew") {
        TextField("brew 路径", text: $model.preferences.brew.brewPath)
        TextField("工作目录", text: $model.preferences.brew.workingDirectory)
        TextField("缓存目录", text: $model.preferences.brew.cacheDirectory)
        Toggle("自动更新 Homebrew", isOn: $model.preferences.brew.autoUpdate)
        Toggle("安装后自动清理", isOn: $model.preferences.brew.autoCleanup)
        TextField("缓存保留天数", value: $model.preferences.pruneDays, format: .number)
        TextField("更新检查间隔（分钟，0 为关闭）", value: $model.preferences.periodicMinutes, format: .number)
      }
      Section("Cask") {
        TextField("应用目录", text: $model.preferences.brew.appDirectory)
        TextField("语言", text: $model.preferences.brew.language)
        TextField("安装选项", text: $model.preferences.brew.caskOptions)
      }
      Section("统计") {
        HStack {
          Button("读取统计状态", systemImage: "chart.bar") { model.enqueue(model.commands.analytics()) }
          Button("开启统计", systemImage: "checkmark.circle") { model.enqueue(model.commands.analytics(enabled: true)) }
          Button("关闭统计", systemImage: "xmark.circle") { model.enqueue(model.commands.analytics(enabled: false)) }
        }
      }
      Button("保存设置", systemImage: "square.and.arrow.down", action: model.savePreferences)
    }.formStyle(.grouped)
  }
}
