// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "Wildbrew", platforms: [.macOS(.v15)],
  products: [
    .library(name: "WildbrewCore", targets: ["WildbrewCore"]),
    .executable(name: "Wildbrew", targets: ["Wildbrew"]),
    .executable(name: "wildbrew-check", targets: ["wildbrew-check"]),
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-subprocess.git", exact: "1.0.0")
  ],
  targets: [
    .target(
      name: "WildbrewCore",
      dependencies: [.product(name: "Subprocess", package: "swift-subprocess")]),
    .executableTarget(name: "Wildbrew", dependencies: ["WildbrewCore"]),
    .executableTarget(name: "wildbrew-check", dependencies: ["WildbrewCore"]),
    .testTarget(name: "WildbrewCoreTests", dependencies: ["WildbrewCore"]),
    .testTarget(name: "WildbrewAppTests", dependencies: ["Wildbrew", "WildbrewCore"]),
  ])
