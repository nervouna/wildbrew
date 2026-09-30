import SwiftUI

struct DiagnosticsView: View {
  @Bindable var model: AppModel
  @State private var severity = "all"
  @State private var fixesOnly = false
  var body: some View {
    ScrollView {
      VStack(alignment: .leading) {
        HStack {
          Button("读取配置", systemImage: "doc.text") { model.enqueue(model.commands.diagnostic("config")) }
          Button("检查环境", systemImage: "stethoscope") { model.enqueue(model.commands.diagnostic("doctor")) }
          Button("检查依赖", systemImage: "point.3.connected.trianglepath.dotted") { model.enqueue(model.commands.diagnostic("missing")) }
          Button("检查链接", systemImage: "link") { model.enqueue(model.commands.diagnostic("linkage")) }
          Button("查看叶节点", systemImage: "leaf") { model.enqueue(model.commands.diagnostic("leaves")) }
        }
        DirectoryView(model: model)
        Divider()
        HStack {
          Picker("严重程度", selection: $severity) {
            Text("全部").tag("all")
            ForEach(["critical", "high", "medium", "low"], id: \.self) { Text($0).tag($0) }
          }.frame(width: 180)
          Toggle("仅可修复", isOn: $fixesOnly)
          Spacer()
          Button("检查漏洞", systemImage: "checkmark.shield") { model.enqueue(model.commands.vulnerabilities(severity: severity == "all" ? nil : severity, fixesOnly: fixesOnly), .vulnerabilities) }
        }
        if let report = model.vulnerabilities {
          LabeledContent("跳过的软件", value: report.skippedFormulae.joined(separator: ", "))
          ForEach(report.findings) { finding in
            GroupBox(finding.formula + " " + finding.version) {
              VStack(alignment: .leading) {
                ForEach(finding.vulnerabilities) { item in
                  LabeledContent(item.id, value: item.severity)
                  Text(item.summary).textSelection(.enabled)
                  LabeledContent("修复版本", value: item.fixedVersions.joined(separator: ", "))
                }
                LabeledContent("已修补", value: finding.patched.map(\.id).joined(separator: ", "))
              }.frame(maxWidth: .infinity, alignment: .leading)
            }
          }
          DisclosureGroup("原始结果") { Text(report.raw.pretty).textSelection(.enabled).font(.system(.body, design: .monospaced)) }
        }
      }.padding()
    }
  }
}
