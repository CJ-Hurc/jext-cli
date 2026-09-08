#!/usr/bin/env bash
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT" || exit 2
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { echo "ok - $*"; }
if JEXT_CLI_ALLOWED=no bash run.sh >/dev/null 2>&1; then
	fail "run.sh should fail without JEXT_CLI_ALLOWED=yes"
fi
ok "run.sh missing-allow fail-closed"
echo "PASS missing-env"
exit 0
