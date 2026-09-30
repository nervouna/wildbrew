import Foundation

enum ResultDestination: Equatable {
  case log, installed, outdated, services, taps, package(String), vulnerabilities, directory(String)
  case brewfile(path: String, revision: Int)
}
