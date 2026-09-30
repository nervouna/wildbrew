import Foundation
import WildbrewCore

struct AppPreferences: Codable {
  var brew = BrewSettings()
  var pruneDays = 30
  var periodicMinutes = 0
  static func load() -> Self {
    guard let data = UserDefaults.standard.data(forKey: "preferences"),
      let value = try? JSONDecoder().decode(Self.self, from: data) else { return Self() }
    return value
  }
  func save() throws {
    var safe = self
    safe.brew.additionalEnvironment = [:]
    UserDefaults.standard.set(try JSONEncoder().encode(safe), forKey: "preferences")
  }
}
