import Foundation
import WildbrewCore

@main struct Check {
  static func main() async {
    var args = Array(CommandLine.arguments.dropFirst())
    guard args.count >= 3, args.removeFirst() == "--brew" else {
      FileHandle.standardError.write(
        Data("Usage: wildbrew-check --brew /path/to/brew [--cwd /path] -- command arguments\n".utf8)
      )
      exit(64)
    }
    var settings = BrewSettings()
    settings.brewPath = args.removeFirst()
    if args.first == "--cwd", args.count >= 2 {
      args.removeFirst()
      settings.workingDirectory = args.removeFirst()
    }
    if args.first == "--" { args.removeFirst() }
    let command = BrewCommand(
      executable: settings.brewPath, arguments: args, title: args.first ?? "brew",
      mutatesState: true)
    do {
      let result = try await BrewRunner().run(command, settings: settings) { event in
        (event.stream == .stdout ? FileHandle.standardOutput : FileHandle.standardError).write(
          event.data)
      }
      exit(Int32(result.exitCode))
    } catch {
      FileHandle.standardError.write(Data("\(error)\n".utf8))
      exit(1)
    }
  }
}
