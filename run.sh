#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Goal     : Fail-closed root entry for CJ-Hurc/jext-cli.
# Purpose  : Refuse direct execution unless JEXT_CLI_ALLOWED=yes; then
#            delegate to the first-party CLI under devtools/.
# Consumers: humans, CI, complete-e2e repository occupancy (missing-env).
# Exit codes: 0 delegated / 1 blocked without allow / delegated
# Side effects: none when blocked; otherwise same as CLI.
# -----------------------------------------------------------------------------
if [[ "${JEXT_CLI_ALLOWED:-}" != "yes" ]]; then
	echo "This script should not be run directly."
	exit 1
fi
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec bash "$ROOT/devtools/jext-cli/run.sh" "$@"
