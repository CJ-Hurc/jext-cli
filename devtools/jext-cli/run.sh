#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Goal     : First-party CLI for CJ-Hurc/jext-cli (PHP Joomla component builder).
# Purpose  : status/--help print usage (no side effects). validate checks
#            README + PHP bin + runtime discovery + occupancy prove contracts.
# Consumers: humans, CI, complete-e2e CLI contract / universal scaffold.
# Exit codes: 0 help/status/validate/config/version / 1 contract fail / 2 usage
# Side effects: none for help/status/config/validate/version (file reads only).
# -----------------------------------------------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

usage() {
	cat <<'USAGE'
usage: devtools/jext-cli/run.sh <status|--help|help|config|validate|version>
  status / --help   Print this help (no side effects).
  config            List first-party entrypoints.
  validate          Fail-closed contract checks on README + CLI + runtime discovery.
  version           Print jext-cli version via PHP bin (requires composer install).
First-party surfaces: README.md, run.sh, bin/jext-cli, devtools/jext-cli/run.sh,
configs/complete-e2e/runtime.json, configs/complete-e2e/list-runtime-clis.sh,
scripts/complete-e2e/prove/{entity,repository}.py.
USAGE
}

require_file() {
	local rel="$1"
	[[ -f "$ROOT/$rel" ]] || { echo "validate fail: missing $rel" >&2; return 1; }
}

cmd="${1:-}"
case "$cmd" in
	status|--help|-h|help)
		usage
		exit 0
		;;
	"")
		usage >&2
		exit 2
		;;
	config)
		printf '%s\n' \
			'README.md' \
			'run.sh' \
			'bin/jext-cli' \
			'devtools/jext-cli/run.sh' \
			'configs/complete-e2e/runtime.json' \
			'configs/complete-e2e/list-runtime-clis.sh' \
			'scripts/complete-e2e/prove/entity.py' \
			'scripts/complete-e2e/prove/repository.py'
		;;
	version)
		command -v php >/dev/null 2>&1 || { echo "php missing" >&2; exit 1; }
		[[ -f "$ROOT/vendor/autoload.php" ]] || { echo "vendor/autoload.php missing — run composer install" >&2; exit 1; }
		php "$ROOT/bin/jext-cli" --version
		;;
	validate)
		require_file "README.md"
		require_file "run.sh"
		require_file "bin/jext-cli"
		require_file "devtools/jext-cli/run.sh"
		require_file "configs/complete-e2e/runtime.json"
		require_file "configs/complete-e2e/list-runtime-clis.sh"
		require_file "scripts/complete-e2e/prove/entity.py"
		require_file "scripts/complete-e2e/prove/repository.py"
		require_file "composer.json"
		require_file "phpunit.xml"
		require_file "tests/CompleteE2e/CompleteE2eLibraryContractTest.php"
		grep -qi 'jext-cli\|JEXT-CLI' "$ROOT/README.md" || { echo "validate fail: README identity" >&2; exit 1; }
		grep -q 'JEXT_CLI_ALLOWED' "$ROOT/run.sh" || { echo "validate fail: root allow gate" >&2; exit 1; }
		grep -q 'usage:' "$ROOT/devtools/jext-cli/run.sh" || { echo "validate fail: CLI usage banner" >&2; exit 1; }
		grep -q 'hurc-complete-e2e-runtime/v1' "$ROOT/configs/complete-e2e/runtime.json" || { echo "validate fail: runtime schema" >&2; exit 1; }
		grep -q 'jext-cli-runtime' "$ROOT/configs/complete-e2e/runtime.json" || { echo "validate fail: runtime adapter id" >&2; exit 1; }
		grep -q 'cli:jext-cli' "$ROOT/configs/complete-e2e/list-runtime-clis.sh" || { echo "validate fail: runtime surface id" >&2; exit 1; }
		head -1 "$ROOT/bin/jext-cli" | grep -q 'php' || { echo "validate fail: bin/jext-cli shebang" >&2; exit 1; }
		# Live PHP exec when vendor is present (clean-room worktrees omit gitignored vendor).
		if [[ -f "$ROOT/vendor/autoload.php" ]] && command -v php >/dev/null 2>&1; then
			php "$ROOT/bin/jext-cli" --version | grep -qi 'jext-cli\|version' || { echo "validate fail: php bin --version" >&2; exit 1; }
		fi
		echo "ok jext-cli validate"
		;;
	*)
		echo "unknown command: $cmd" >&2
		usage >&2
		exit 2
		;;
esac
