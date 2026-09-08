#!/usr/bin/env bash
# Universal cleanup occupancy: temp dirs do not leak.
set -euo pipefail
scratch="$(mktemp -d "${TMPDIR:-/tmp}/jext-cli-cleanup-XXXXXX")"
marker="$scratch/marker"
echo temporary >"$marker"
[[ -f "$marker" ]]
rm -rf "$scratch"
[[ ! -e "$scratch" ]]
exit 0
