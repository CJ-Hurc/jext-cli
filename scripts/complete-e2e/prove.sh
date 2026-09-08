#!/usr/bin/env bash
# Machine-prove jext-cli (dual-origin CLI runtime + occupancy + proof-receipt).
set -uo pipefail
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
	echo "Usage: scripts/complete-e2e/prove.sh"
	echo "Help: prove dual-origin CLI + occupancy scripts + PHP library contract."
	exit 0
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT" || exit 2
fail=0
pass() { printf 'PASS %s\n' "$*"; }
fail_one() { printf 'FAIL %s\n' "$*"; fail=1; }

bash configs/complete-e2e/list-runtime-clis.sh | grep -q '"id": "cli:jext-cli"' && pass "runtime cli:jext-cli" || fail_one "runtime missing cli:jext-cli"
[[ -f configs/complete-e2e/runtime.json ]] && pass "runtime.json" || fail_one "runtime.json missing"
[[ -f devtools/jext-cli/run.sh ]] && pass "devtools/jext-cli/run.sh" || fail_one "devtools missing"
[[ -f bin/jext-cli ]] && pass "bin/jext-cli" || fail_one "bin missing"
[[ -f scripts/complete-e2e/prove/repository.py ]] && pass "repository.py" || fail_one "repository.py missing"
[[ -f scripts/complete-e2e/prove/entity.py ]] && pass "entity.py" || fail_one "entity.py missing"

if bash devtools/jext-cli/run.sh validate; then
	pass "cli validate"
else
	fail_one "cli validate"
fi
if bash devtools/jext-cli/run.sh status >/dev/null; then
	pass "cli status"
else
	fail_one "cli status"
fi
help_out="$(bash devtools/jext-cli/run.sh --help 2>&1 || true)"
printf '%s' "$help_out" | grep -qiE 'usage|status|validate' && pass "cli --help" || fail_one "cli --help"

if bash scripts/complete-e2e/fault/missing-env.sh; then
	pass "occupancy missing-env"
else
	fail_one "occupancy missing-env"
fi
if bash scripts/complete-e2e/fault/invalid-config.sh; then
	pass "occupancy invalid-config"
else
	fail_one "occupancy invalid-config"
fi

if [[ -x vendor/bin/phpunit ]]; then
	if php vendor/bin/phpunit -c phpunit.xml --no-coverage; then
		pass "phpunit library contract"
	else
		fail_one "phpunit library contract"
	fi
else
	fail_one "vendor/bin/phpunit missing"
fi

[[ "$fail" -eq 0 ]] || exit 1
printf 'OK jext-cli-complete-e2e-prove\n'
exit 0
