#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Goal     : Emit jext-cli CLI surfaces as JSON for complete-e2e compile.
# Purpose  : Dual-origin runtime discovery matching static cli:jext-cli.
# Consumers: configs/complete-e2e/runtime.json adapter jext-cli-runtime.
# Outputs  : stdout JSON {surfaces:[...]} only.
# Exit codes: 0 ok / 1 missing python3
# Side effects: none.
# -----------------------------------------------------------------------------
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
command -v python3 >/dev/null 2>&1 || { echo "python3 required" >&2; exit 1; }
python3 - "$ROOT" <<'PY'
import json, sys
from pathlib import Path

root = Path(sys.argv[1])
candidates = [
    ("cli:jext-cli", "devtools/jext-cli/run.sh"),
]
surfaces = []
for sid, rel in candidates:
    p = root / rel
    if p.is_file():
        surfaces.append({
            "id": sid,
            "kind": "cli",
            "path": rel,
            "origin": "runtime",
            "discovered": True,
        })
print(json.dumps({"surfaces": surfaces}))
PY
