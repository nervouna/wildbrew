# Local validation

Validated on September 30, 2026. The macOS app targets macOS 15 and later. This acceptance run used an Apple Silicon Tart guest running macOS 26.6.2 (25G83) with Homebrew 7.0.7-38-g7cce6ea. It does not establish Intel or macOS 15 runtime compatibility.

## Build and focused tests

Debug and release builds succeeded. Seven tests passed, covering command construction, parsing, subprocess cancellation, queue settings, Brewfile result routing, and privileged process-group cancellation. The app bundle passed ad hoc signature verification. The accepted executable SHA-256 is `2f8bb84d18222106d5feab87453211ec9b544adaca069ec3e30aa771ba1e293e`.

## Guest acceptance

CLI acceptance used `wildbrew-check`, which invokes the same `BrewRunner` as the app. Dedicated local Formula and Cask fixtures exercised real Homebrew writes.

| Area | Verified behavior |
| --- | --- |
| Packages | Formula and Cask install, upgrade, reinstall, uninstall; pin and unpin; Cask zap; installed/outdated JSON; source install, HEAD installation, historical version installation, fetch and postinstall |
| Services | User start, stop, restart, kill, run and cleanup; root start and stop; running and registration state |
| Environment | Brewfile dump, list, check, install, add, remove, preview cleanup and force cleanup |
| Maintenance | Cleanup and autoremove, dependency and reverse-dependency queries, missing dependencies, linkage, files, sizes, links and paths |
| Sources and diagnostics | Tap add/remove and trust records; configuration, doctor, vulnerability JSON, analytics state and updates |
| Native GUI | Catalog search and package metadata; actual Formula install, uninstall and reinstall; user and system services; administrator authentication; Terminal handoff; Brewfile open, edit and save through native file dialogs |

The compact-window package list defect found during GUI acceptance was repaired and visually rechecked. A privileged cancellation defect was reproduced with a delayed root write, repaired with a task lifetime supervisor, and retested in the guest. After cancellation, the root process exited, the delayed marker remained absent beyond its deadline, and the service remained stopped. The queue resumed successfully.

The Terminal handoff ran the quoted command and returned the expected Homebrew repository path after the guest's native automation permission was allowed. Brewfile edits survived saving, passed Ruby syntax validation and remained readable by `brew bundle list`.

Fixture setup failures were repaired in the guest: an overwriting postinstall marker, the explicit Git download strategy for a local HEAD URL, and linking/install receipts around historical-version experiments. These failures were not attributed to the GUI.

## Host isolation and retention

The VM has 2 CPUs and 4096 MiB RAM. It ran without host clipboard, audio or USB access. Only the app build directory was shared, read-only. No host Homebrew write command was used. Host package versions, pins, linked kegs, services and Tap lists matched the read-only baseline after acceptance.

The reusable VM is `wildbrew-test`. Its disk and the downloaded OCI image cache remain under `.local/tart`; the Tart binary remains under `.local/tools`. `scripts/tart.sh` sets `TART_NO_AUTO_PRUNE=1`. Stop the guest after use; do not delete the VM or prune its image cache when preserving this environment.

Local raw evidence is retained in the ignored `.local/acceptance/2026-09-30/` directory. It includes build/test logs, guest command results, screenshots, source hashes and host state comparisons. Temporary VNC credentials are excluded. The app and acceptance helper are in `dist/`, also ignored by Git.

## Task progress indicator

A subsequent UI change adds native indeterminate linear progress bars to the task console and running rows in the task table. It follows the running queue entry even when another entry is selected; it does not derive or display a completion percentage.

The release build and signature verification passed. In the retained Tart guest, a delayed wrapper delegated to real `brew update`; progress appeared while the task ran and disappeared after completion. A second run verified cancellation and removal of the progress indicator. Screenshots and build evidence are retained in `.local/acceptance/progress/`. The updated executable SHA-256 is `d743c17b4140d191305f1b4105d436e532f64bbd7e276e9f8b1aa6b6c4ee46e4`. This UI-only change added no tests and reused the earlier core and queue test evidence.
