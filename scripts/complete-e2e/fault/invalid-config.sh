#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT" || exit 2
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok - $*"; }
if bash devtools/jext-cli/run.sh not-a-real-command >/dev/null 2>&1; then
	fail "unknown command should fail"
fi
ok "devtools unknown-command fail-closed"
if bash devtools/jext-cli/run.sh --hurc-ce2e-no-such-flag >/dev/null 2>&1; then
	fail "unknown flag should fail"
fi
ok "devtools unknown-flag fail-closed"
echo "PASS invalid-config"
exit 0
