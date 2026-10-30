# Contributing

Wildbrew is a personal, experimental project, but bug reports and fixes are welcome.

## Issues

- **Bugs:** use the bug report form. The most useful reports give the section and button, the task's command (复制命令, Copy command) and output, what happened and what you expected; a suggested fix is a bonus.
- **Security problems:** report them privately, see [SECURITY.md](SECURITY.md).
- **Feature ideas:** open an issue to discuss it first. Wildbrew stays small on purpose, so not every idea will fit.

## How the project is developed

[docs/architecture.md](docs/architecture.md) describes the design and how it is tested. In short:

- Unit tests pass: `swift test --disable-sandbox --scratch-path /private/tmp/wildbrew-build --jobs 2`.
- The app builds and its signature verifies: `./scripts/build-app.sh`.
- Commands are built as argument lists, not shell strings. Shell scripts are only for the administrator prompt and the Terminal handoff, with every argument quoted.
- Nothing writes on launch; every write is a user action.
- Changes that run real Homebrew writes are tested in a disposable Tart VM (`./scripts/tart.sh`), never against the host's Homebrew. Record what was verified in [docs/validation.md](docs/validation.md); a passing build is not acceptance.
- The interface is in Chinese. Technical documentation and code comments are in English.

## Pull requests

Describe the change, link the issue if there is one, and list the commands you ran and their results. Say which macOS version and Homebrew version you tested on, and whether you tested real writes in a VM.
