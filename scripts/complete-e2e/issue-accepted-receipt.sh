#!/usr/bin/env bash
# Issue kernel-shaped AcceptedProofReceipt into the active complete-e2e run.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HURC_CORE_SRC="${HURC_CORE_SRC:-/workspace/worktrees/hurc-harness-v2-prover-live/core/src}"
ISSUER="${HURC_COMPLETE_E2E_ISSUE_ACCEPTED:-/workspace/worktrees/hurc-harness-v2-prover-live/extensions/shared/contributions/capabilities/complete-e2e/scripts/issue-accepted-receipt.ts}"
STATE="$ROOT/.hurc-harness/state/complete-e2e"
ACTIVE="$STATE/active-run.json"
[[ -f "$ACTIVE" ]] || { echo "no active-run" >&2; exit 1; }
RUN_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["run_id"])' "$ACTIVE")"
RUN_DIR="$STATE/runs/$RUN_ID"
SNAP="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1])).get("snapshot_id",""))' "$RUN_DIR/run.json")"
[[ -n "$SNAP" ]] || { echo "missing snapshot_id" >&2; exit 1; }
export HURC_CORE_SRC PROJECT_ROOT="$ROOT" RECEIPT_OUT="$RUN_DIR/proof-receipt.json" SNAPSHOT_ID="$SNAP" CE2E_ISSUE_PLAN_JSON="$ROOT/configs/complete-e2e/issue-plan.json"
command -v bun >/dev/null || { echo "bun required" >&2; exit 1; }
[[ -f "$ISSUER" ]] || { echo "issuer missing: $ISSUER" >&2; exit 1; }
bun "$ISSUER"
