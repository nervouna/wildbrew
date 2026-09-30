import Foundation
import Subprocess
import System

public enum BrewOutputStream: String, Sendable { case stdout, stderr }
public struct BrewOutput: Sendable {
  public let stream: BrewOutputStream
  public let data: Data
  public var text: String { String(decoding: data, as: UTF8.self) }
}
public struct BrewResult: Sendable {
  public let command: BrewCommand
  public let stdout: Data
  public let stderr: Data
  public let exitCode: Int
  public var succeeded: Bool { exitCode == 0 }
  public var output: String { String(decoding: stdout, as: UTF8.self) }
  public var errorOutput: String { String(decoding: stderr, as: UTF8.self) }
}
public struct BrewExecutionError: Error, LocalizedError, Sendable {
  public let result: BrewResult
  public var errorDescription: String? {
    result.errorOutput.isEmpty ? "\(result.command.title): \(result.exitCode)" : result.errorOutput
  }
}
public struct BrewRunner: Sendable {
  public init() {}
  public func run(
    _ command: BrewCommand, settings: BrewSettings,
    onOutput: @escaping @Sendable (BrewOutput) async -> Void = { _ in }
  ) async throws -> BrewResult {
    let command = settings.configured(command)
    var options = PlatformOptions()
    options.createSession = true
    options.teardownSequence = [
      .gracefulShutDown(toProcessGroup: true, allowedDurationToNextStep: .seconds(2))
    ]
    let result = try await Subprocess.run(
      .path(FilePath(command.executable)), arguments: Arguments(command.arguments),
      environment: .inherit.updating(
        Dictionary(
          uniqueKeysWithValues: settings.environment(for: command).map {
            (Environment.Key(stringLiteral: $0.key), Optional($0.value))
          })), workingDirectory: FilePath(settings.workingDirectory), platformOptions: options,
      input: .none, output: .sequence, error: .sequence
    ) { execution in
      async let stdout = collect(execution.standardOutput, stream: .stdout, onOutput: onOutput)
      async let stderr = collect(execution.standardError, stream: .stderr, onOutput: onOutput)
      return try await (stdout, stderr)
    }
    try Task.checkCancellation()
    let code: Int
    switch result.terminationStatus {
    case .exited(let value): code = Int(value)
    case .signaled(let value): code = Int(value) + 128
    }
    return BrewResult(
      command: command, stdout: result.closureResult.0, stderr: result.closureResult.1,
      exitCode: code)
  }
  public func checked(
    _ command: BrewCommand, settings: BrewSettings,
    onOutput: @escaping @Sendable (BrewOutput) async -> Void = { _ in }
  ) async throws -> BrewResult {
    let result = try await run(command, settings: settings, onOutput: onOutput)
    if !result.succeeded { throw BrewExecutionError(result: result) }
    return result
  }
}
private func collect(
  _ sequence: SubprocessOutputSequence, stream: BrewOutputStream,
  onOutput: @escaping @Sendable (BrewOutput) async -> Void
) async throws -> Data {
  var data = Data()
  for try await buffer in sequence {
    let chunk = buffer.withUnsafeBytes { Data($0) }
    data.append(chunk)
    await onOutput(BrewOutput(stream: stream, data: chunk))
  }
  return data
}
