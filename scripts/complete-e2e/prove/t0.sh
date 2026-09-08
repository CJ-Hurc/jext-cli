#!/usr/bin/env bash
# Auto-run by complete-e2e _ensure_product_occupancy (stem: t0).
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
exec python3 "$ROOT/scripts/complete-e2e/prove/repository.py"
