#!/bin/bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
exec env TART_HOME="$repo/.local/tart" TART_NO_AUTO_PRUNE=1 "$repo/.local/tools/tart.app/Contents/MacOS/tart" "$@"
