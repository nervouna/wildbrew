import Foundation

public struct BrewClient: Sendable {
  public var settings: BrewSettings
  public var commands: CommandFactory { CommandFactory(brewPath: settings.brewPath) }
  public var runner = BrewRunner()
  public init(settings: BrewSettings = BrewSettings()) { self.settings = settings }
  public func installed() async throws -> [BrewPackage] {
    try PackageParser.installed(
      await runner.checked(commands.installed(), settings: settings).stdout)
  }
  public func outdated(greedy: Bool = false) async throws -> [OutdatedPackage] {
    try OutdatedPackage.parse(
      await runner.checked(commands.outdated(greedy: greedy), settings: settings).stdout)
  }
  public func services(system: Bool = false) async throws -> [BrewService] {
    try BrewService.parse(
      await runner.checked(commands.services(system: system), settings: settings).stdout)
  }
  public func taps() async throws -> [BrewTap] {
    try BrewTap.parse(await runner.checked(commands.tapInfo(), settings: settings).stdout)
  }
  public func info(_ package: BrewPackage) async throws -> BrewPackage? {
    try PackageParser.installed(
      await runner.checked(commands.info(package), settings: settings).stdout
    ).first
  }
  public func catalog(kind: PackageKind) async throws -> [BrewPackage] {
    let url = URL(string: "https://formulae.brew.sh/api/\(kind.rawValue).json")!
    let (data, response) = try await URLSession.shared.data(from: url)
    if let response = response as? HTTPURLResponse, !(200..<300).contains(response.statusCode) {
      throw URLError(.badServerResponse)
    }
    return try PackageParser.catalog(data, kind: kind)
  }
}
