import Foundation

public enum PackageKind: String, Codable, CaseIterable, Sendable {
  case formula, cask
  public var flag: String { "--" + rawValue }
}
public struct BrewPackage: Identifiable, Sendable, Equatable {
  public let kind: PackageKind
  public let name: String
  public let fullName: String
  public let displayName: String
  public let summary: String
  public let homepage: String
  public let version: String
  public let installedVersions: [String]
  public let tap: String
  public let license: String
  public let dependencies: [String]
  public let pinned: Bool
  public let autoUpdates: Bool
  public let installedOnRequest: Bool
  public let caveats: String
  public let raw: JSONValue
  public var id: String { kind.rawValue + ":" + fullName }
  public var isInstalled: Bool { !installedVersions.isEmpty }
  public init(kind: PackageKind, json: JSONValue) {
    self.kind = kind
    raw = json
    name = json[kind == .formula ? "name" : "token"].string ?? ""
    fullName = json[kind == .formula ? "full_name" : "full_token"].string ?? name
    displayName = kind == .cask ? (json["name"].strings.first ?? name) : name
    summary = json["desc"].string ?? ""
    homepage = json["homepage"].string ?? ""
    version =
      kind == .formula
      ? (json["versions"]["stable"].string ?? "HEAD") : (json["version"].string ?? "")
    if kind == .formula {
      installedVersions = json["installed"].array.compactMap { $0["version"].string }
    } else {
      installedVersions = json["installed"].string.map { [$0] } ?? json["installed"].strings
    }
    tap = json["tap"].string ?? (kind == .formula ? "homebrew/core" : "homebrew/cask")
    license = json["license"].display
    pinned = json["pinned"].bool
    autoUpdates = json["auto_updates"].bool
    installedOnRequest = json["installed"].array.contains { $0["installed_on_request"].bool }
    dependencies =
      kind == .formula ? json["dependencies"].strings : json["depends_on"]["formula"].strings
    caveats = json["caveats"].string ?? ""
  }
}
public enum PackageParser {
  private static func compactCatalog(_ json: JSONValue) -> JSONValue {
    let keys = [
      "name", "token", "full_name", "full_token", "desc", "homepage", "versions", "version", "tap",
      "license", "dependencies", "depends_on", "auto_updates", "caveats",
    ]
    return .object(Dictionary(uniqueKeysWithValues: keys.map { ($0, json[$0]) }))
  }
  public static func installed(_ data: Data) throws -> [BrewPackage] {
    let root = try JSONDecoder().decode(JSONValue.self, from: data)
    return root["formulae"].array.map { BrewPackage(kind: .formula, json: $0) }
      + root["casks"].array.map { BrewPackage(kind: .cask, json: $0) }
  }
  public static func catalog(_ data: Data, kind: PackageKind) throws -> [BrewPackage] {
    try JSONDecoder().decode([JSONValue].self, from: data).map {
      BrewPackage(kind: kind, json: compactCatalog($0))
    }
  }
}
