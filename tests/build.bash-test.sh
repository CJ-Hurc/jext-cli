#!/usr/bin/env bash
# Universal build occupancy: validate + committed contracts succeed.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
bash "$ROOT/devtools/jext-cli/run.sh" validate
bash "$ROOT/devtools/jext-cli/run.sh" status >/dev/null
bash "$ROOT/devtools/jext-cli/run.sh" config >/dev/null
[[ -f "$ROOT/bin/jext-cli" ]]
[[ -f "$ROOT/composer.json" ]]
[[ -f "$ROOT/phpunit.xml" ]]
[[ -f "$ROOT/configs/complete-e2e/runtime.json" ]]
exit 0
