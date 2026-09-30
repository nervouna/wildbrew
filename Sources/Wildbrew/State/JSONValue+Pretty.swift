import Foundation
import WildbrewCore

extension JSONValue {
  var pretty: String {
    let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return String(decoding: (try? encoder.encode(self)) ?? Data(), as: UTF8.self)
  }
}
