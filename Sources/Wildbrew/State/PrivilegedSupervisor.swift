import Foundation
import WildbrewCore

/// The privileged process watches a user-owned lifetime marker independently of osascript.
struct PrivilegedSupervisor: Sendable {
  let directory: URL
  var token: URL { directory.appending(path: "alive") }
  var finished: URL { directory.appending(path: "finished") }

  init() throws {
    directory = URL.temporaryDirectory.appending(path: "wildbrew-task-" + UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false,
      attributes: [.posixPermissions: 0o700])
    do { try Data().write(to: token) }
    catch { try? FileManager.default.removeItem(at: directory); throw error }
  }
  func cancel() { try? FileManager.default.removeItem(at: token) }
  func finish() async {
    cancel()
    // Root cleanup gets time to reap its group before the next queued command starts.
    let deadline = Date.now.addingTimeInterval(2)
    while !FileManager.default.fileExists(atPath: finished.path) && Date.now < deadline {
      do { try await Task.sleep(for: .milliseconds(50)) } catch { break }
    }
    try? FileManager.default.removeItem(at: directory)
  }
  func command(shell: String, title: String, mutatesState: Bool) -> BrewCommand {
    BrewCommand(executable: "/usr/bin/perl",
      arguments: ["-e", Self.program, token.path, finished.path, "/bin/sh", "-c", shell],
      title: title, mutatesState: mutatesState)
  }
  func shellCommand(shell: String, title: String, mutatesState: Bool) -> String {
    let command = command(shell: shell, title: title, mutatesState: mutatesState)
    return ([command.executable] + command.arguments).map(TaskRecord.quote).joined(separator: " ")
  }

  private static let program = #"""
use strict;
use warnings;
use POSIX qw(setsid WNOHANG);
my ($token, $finished, @command) = @ARGV;
sub complete { if (open(my $file, '>', $finished)) { close($file); } }
if (!-e $token) { complete(); exit 130; }
my $pid = fork();
if (!defined $pid) { complete(); die "fork: $!"; }
if ($pid == 0) {
  setsid() >= 0 or die "setsid: $!";
  exit 130 if !-e $token;
  exec { $command[0] } @command;
  die "exec: $!";
}
my $cancelled = 0;
while (1) {
  my $result = waitpid($pid, WNOHANG);
  if ($result == $pid) {
    my $status = $?;
    complete();
    exit($cancelled ? 130 : (($status & 127) ? 128 + ($status & 127) : $status >> 8));
  }
  if (!-e $token) {
    $cancelled = 1;
    kill 'TERM', -$pid;
    select(undef, undef, undef, 0.5);
    # Always kill the group, even if the immediate child exited during TERM.
    kill 'KILL', -$pid;
    waitpid($pid, 0);
    complete();
    exit 130;
  }
  select(undef, undef, undef, 0.05);
}
"""#
}
