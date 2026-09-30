import Foundation

public struct OutdatedPackage: Identifiable, Sendable, Equatable {
  public let kind: PackageKind
  public let name: String
  public let installedVersions: [String]
  public let currentVersion: String
  public let pinned: Bool
  public var id: String { kind.rawValue + ":" + name }
  public static func parse(_ data: Data) throws -> [Self] {
    let root = try JSONDecoder().decode(JSONValue.self, from: data)
    return PackageKind.allCases.flatMap { kind in
      root[kind == .formula ? "formulae" : "casks"].array.map { v in
        Self(
          kind: kind, name: v["name"].string ?? v["token"].string ?? "",
          installedVersions: v["installed_versions"].strings,
          currentVersion: v["current_version"].string ?? "", pinned: v["pinned"].bool)
      }
    }
  }
}
public struct BrewService: Identifiable, Sendable, Equatable {
  public let name: String
  public let status: String
  public let user: String
  public let file: String
  public let raw: JSONValue
  public var id: String { name }
  public static func parse(_ data: Data) throws -> [Self] {
    try JSONDecoder().decode([JSONValue].self, from: data).map {
      Self(
        name: $0["name"].string ?? "", status: $0["status"].string ?? "",
        user: $0["user"].string ?? "", file: $0["file"].string ?? "", raw: $0)
    }
  }
}
public struct BrewTap: Identifiable, Sendable, Equatable {
  public let name: String
  public let remote: String
  public let formulaNames: [String]
  public let caskTokens: [String]
  public let raw: JSONValue
  public var id: String { name }
  public static func parse(_ data: Data) throws -> [Self] {
    try JSONDecoder().decode([JSONValue].self, from: data).map {
      Self(
        name: $0["name"].string ?? "", remote: $0["remote"].string ?? "",
        formulaNames: $0["formula_names"].strings, caskTokens: $0["cask_tokens"].strings, raw: $0)
    }
  }
}
public struct VulnerabilityReport: Sendable, Equatable {
  public let raw: JSONValue
  public var skippedFormulae: [String] { raw["skipped_formulae"].strings }
  public var findings: [VulnerabilityFinding] {
    raw["findings"].array.map(VulnerabilityFinding.init)
  }
  public init(data: Data) throws { raw = try JSONDecoder().decode(JSONValue.self, from: data) }
}

public struct VulnerabilityFinding: Identifiable, Sendable, Equatable {
  public let raw: JSONValue
  public init(_ raw: JSONValue) { self.raw = raw }
  public var id: String { formula }
  public var formula: String { raw["formula"].string ?? "" }
  public var version: String { raw["version"].string ?? "" }
  public var vulnerabilities: [Vulnerability] {
    raw["vulnerabilities"].array.map(Vulnerability.init)
  }
  public var patched: [Vulnerability] { raw["patched"].array.map(Vulnerability.init) }
}
public struct Vulnerability: Identifiable, Sendable, Equatable {
  public let raw: JSONValue
  public init(_ raw: JSONValue) { self.raw = raw }
  public var id: String { raw["id"].string ?? "" }
  public var severity: String { raw["severity"].string ?? "" }
  public var summary: String { raw["summary"].string ?? "" }
  public var aliases: [String] { raw["aliases"].strings }
  public var fixedVersions: [String] { raw["fixed_versions"].strings }
}
