# Security

Wildbrew runs Homebrew commands on its user's Mac: it installs and removes software, runs Brewfiles, adds taps, and runs system service commands as root after the macOS administrator prompt. A flaw could make it run a command the user did not choose, or run one with more privilege than intended.

## Reporting a vulnerability

Please do not open a public issue for a security problem. Report it privately through GitHub: **Security → Report a vulnerability** on this repository ([direct link](https://github.com/nervouna/wildbrew/security/advisories/new)). Include what you did, what happened, and the commit you built.

You will get an answer within a week. Fixes land on `main`; there are no maintained release branches.

## In scope

- Input Wildbrew reads (package names and metadata from the catalog or a tap, Brewfile content, settings) that makes it run a command, or arguments, other than the one shown in the task
- A way to run something as root other than the system service command the user started, or to keep a root process running after the task is cancelled
- A command handed to Terminal that differs from the one shown by 复制命令 (Copy command)

## Out of scope

- What Homebrew, a formula, a cask or a tap does when Wildbrew runs it as asked: report those to Homebrew or the tap's maintainer
- Destructive actions doing what they say, such as 清理环境 (Clean up environment) or 卸载并移除数据 (Uninstall and remove data)
- Anything that needs the user's administrator password or an already compromised user account
- The ad hoc signature of local builds
