# Architecture and development

Wildbrew targets macOS 15 and Swift 6.2. Swift Package Manager builds the native SwiftUI application, the `WildbrewCore` library, and the `wildbrew-check` acceptance CLI. Swift Subprocess 1.0.0 runs commands with separate streaming stdout and stderr and process-group cancellation. No Xcode project generator is required.

## Components

`WildbrewCore` contains JSON models, the command factory, configuration, and subprocess execution. CLI and GUI share that layer. `Sources/Wildbrew/State` owns observable main-actor state, serial execution, task records, and preferences. Feature views live in `Sources/Wildbrew/Views`. The native `NavigationSplitView`, multi-selection `Table`, forms, file panels, and SF Symbols require no third-party UI framework.

Official Formula and Cask catalogs come from the Homebrew JSON API. Installed records override catalog entries by kind and full name, retaining actual installed versions, pinning, and installation provenance. Tap package names come from `tap-info --installed --json=v1`; individual records are obtained through `info --json=v2`. Details, files, size output, dependencies, link state and raw JSON come from the installed Homebrew executable. Service records use `services info --all --json`, keeping `running` and `registered` independent.

Every queued task snapshots its settings. The main-actor queue runs one process at a time, appends output, records exit status, and refreshes actual installed/outdated/service/tap/directory state after every mutating attempt, including failures and cancellation. Metadata caches are invalidated when installed records refresh. System service commands use `osascript` with the native administrator prompt and return captured JSON or logs to the same queue. A built-in Perl/POSIX supervisor creates an independent process group for the privileged shell and watches a per-task lifetime marker in a private temporary directory. Cancellation removes the marker immediately; the supervisor sends TERM then KILL to the whole group, reaps its child, and acknowledges completion. It checks the marker before launching, so a delayed authentication response cannot start an already-cancelled command. Cancellation requires no second administrator prompt. The queue allows root cleanup to finish before advancing, then removes temporary files. This terminates an in-flight command and its process-group descendants; it does not undo mutations already completed or stop services already registered with launchd. Terminal handoff shell-quotes executable, arguments, configured environment overrides and working directory. It never reports external completion; the user refreshes after the command finishes.

The runner inherits the application process environment and applies settings overrides. Terminal inherits its own session environment and applies the same overrides; unrelated inherited environment can differ. No credential editor or credential storage is provided. Preferences use Codable data in UserDefaults; additional environment values are excluded from persistence. Task history is session-only. Brewfiles remain raw Ruby and are saved atomically to user-selected paths, rather than parsed or rewritten by the GUI. Bundle add/remove/dump reload the file produced by Homebrew.

## Build and test

App packaging uses Xcode with Icon Composer support to compile `Resources/AppIcon/WildbrewAppIcon.icon`. The native document disables Liquid Glass. See [app icon](../Resources/AppIcon/README.md) for source assets and runtime validation.

```sh
swift test --disable-sandbox --scratch-path /private/tmp/wildbrew-build --jobs 2
./scripts/build-app.sh
```

The script builds release products with two jobs, writes ignored `dist/Wildbrew.app` and `dist/wildbrew-check`, generates Info.plist, applies ad hoc signatures, and verifies the app signature. Override the scratch directory through `WILDBREW_BUILD_PATH`. The script does not install host software or change host Homebrew. Install a built app by copying it to an application directory. Rebuild and replace the copy to update it. Ad hoc signing is local development signing; distribution notarization is a separate release step.

Core tests cover command argument boundaries, JSON decoding and process behavior. GUI state tests cover serial queue execution, task cancellation, settings snapshots, Brewfile editor ownership, and the privileged supervisor's quoting, nested-child cancellation and late-launch rejection using disposable unprivileged shell commands. Actual root authentication and cancellation are verified separately in the guest. Build success and unit tests are separate from real Homebrew and UI acceptance.

## Commands and networking

Command behavior follows the installed Homebrew version; the current command contract is documented in the [Homebrew manual](https://docs.brew.sh/Manpage). The app uses command arguments rather than composing shell strings for ordinary execution. Shell scripts are used only for native administrator authentication and explicit Terminal handoff, with single-quote escaping of every argument. Homebrew may contact package taps, artifact download servers, GitHub and OSV.dev. Catalog downloads use URLSession against `https://formulae.brew.sh/api/`. Analytics uses Homebrew's persistent analytics setting.

The GUI contains no automatic write operation on launch. Refresh and optional periodic checks read actual state; the periodic check defaults to disabled. Writes are user actions. Cask `--zap` and `bundle cleanup --force` are distinct explicit actions. Homebrew may update or clean during installation according to configured settings. Cached package catalogs and task output stay in memory and are released when the app exits.

## Isolated acceptance

Use a disposable Tart macOS VM to test real writes. The initial allocation is two virtual CPUs and 4 GiB RAM. Install Homebrew and copy the signed app/CLI into the guest, then verify actual package installation/removal, Cask behavior, service running and registration states, dependencies, Taps and trust, Brewfile file changes, cleanup previews/writes, diagnostics, update/pin behavior, cancellation and Terminal handoff. Keep host Homebrew read-only. Capture guest command results and UI screenshots outside the repository. Stop the VM after acceptance and retain both its disk and the downloaded image/cache for reuse. The project-local Tart binary is `.local/tools/tart.app`; set `TART_HOME` to the absolute project path followed by `/.local/tart` and `TART_NO_AUTO_PRUNE=1` for every Tart command. Run Tart through `./scripts/tart.sh`, which applies both variables. Reuse the existing VM/image rather than downloading another copy. Do not delete or prune these retained artifacts. Acceptance results belong in the delivery report, rather than being implied by a successful build.
