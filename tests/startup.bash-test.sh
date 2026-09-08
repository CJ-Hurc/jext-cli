#!/usr/bin/env bash
# Universal startup occupancy: CLI help starts healthy.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
out="$(bash "$ROOT/devtools/jext-cli/run.sh" help)"
printf '%s' "$out" | grep -qiE 'usage|help'
exit 0
