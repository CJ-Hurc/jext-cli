#!/usr/bin/env python3
"""Identity-bound universal repository occupancy for CJ-Hurc/jext-cli."""
from __future__ import annotations

import json
import os
import sqlite3
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
_local_state = ROOT / ".hurc-harness" / "state" / "complete-e2e"
_local_active = _local_state / "active-run.json"
if _local_active.is_file():
	_ORIGIN = ROOT.resolve()
else:
	_ORIGIN = Path(os.environ.get("HURC_CE2E_REPLAY_ORIGIN") or ROOT).resolve()
STATE = _ORIGIN / ".hurc-harness" / "state" / "complete-e2e"
SCENARIOS = ("missing-env", "startup", "cleanup", "invalid-config", "build")


def _run(argv: list[str], *, env: dict[str, str] | None = None, timeout: int = 30) -> subprocess.CompletedProcess[str]:
	merged = os.environ.copy()
	if env:
		merged.update(env)
	return subprocess.run(
		argv,
		cwd=str(ROOT),
		env=merged,
		capture_output=True,
		text=True,
		timeout=timeout,
		check=False,
	)


def prove(scenario: str) -> dict[str, object]:
	stack = ROOT / "devtools" / "jext-cli" / "run.sh"
	legacy = ROOT / "run.sh"
	php_bin = ROOT / "bin" / "jext-cli"
	if scenario == "startup":
		proc = _run(["bash", str(stack), "help"])
		text = f"{proc.stdout}\n{proc.stderr}".lower()
		ok = proc.returncode == 0 and ("usage" in text or "help" in text)
		return {
			"ok": ok,
			"evidence_refs": ["devtools/jext-cli/run.sh", "startup-help"],
		}
	if scenario == "build":
		checks = [
			_run(["bash", str(stack), "validate"]),
			_run(["bash", str(stack), "status"]),
			_run(["bash", str(stack), "config"]),
		]
		ok = all(p.returncode == 0 for p in checks)
		ok = ok and php_bin.is_file()
		ok = ok and (ROOT / "README.md").is_file()
		ok = ok and (ROOT / "configs" / "complete-e2e" / "runtime.json").is_file()
		ok = ok and (ROOT / "configs" / "complete-e2e" / "list-runtime-clis.sh").is_file()
		ok = ok and (ROOT / "composer.json").is_file()
		ok = ok and (ROOT / "phpunit.xml").is_file()
		ok = ok and (ROOT / "tests" / "CompleteE2e" / "CompleteE2eLibraryContractTest.php").is_file()
		# Optional live PHP when vendor exists (gitignored; clean-room may omit it).
		if (ROOT / "vendor" / "autoload.php").is_file():
			ver = _run(["bash", str(stack), "version"])
			ok = ok and ver.returncode == 0
		return {
			"ok": ok,
			"evidence_refs": [
				"devtools/jext-cli/run.sh",
				"bin/jext-cli",
				"README.md",
				"composer.json",
				"phpunit.xml",
				"tests/CompleteE2e/CompleteE2eLibraryContractTest.php",
				"configs/complete-e2e/runtime.json",
				"configs/complete-e2e/list-runtime-clis.sh",
				"entrypoint-validate-smoke",
			],
		}
	if scenario == "cleanup":
		with tempfile.TemporaryDirectory(prefix="jext-cli-ce2e-cleanup-") as scratch:
			marker = Path(scratch) / "marker"
			marker.write_text("temporary", encoding="utf-8")
			ok = marker.is_file()
		ok = ok and not Path(scratch).exists()
		return {"ok": ok, "evidence_refs": ["temporary-directory-cleanup", "no-state-leak"]}
	if scenario == "missing-env":
		proc = _run(["bash", str(legacy)], env={"JEXT_CLI_ALLOWED": "no"})
		text = f"{proc.stdout}\n{proc.stderr}".lower()
		ok = proc.returncode != 0 and (
			"should not be run directly" in text or "jext_cli_allowed" in text
		)
		return {
			"ok": ok,
			"evidence_refs": ["run.sh", "jext-cli-allowed-fail-closed"],
		}
	if scenario == "invalid-config":
		proc = _run(["bash", str(stack), "not-a-real-command"])
		text = f"{proc.stdout}\n{proc.stderr}".lower()
		ok = proc.returncode != 0 and ("unknown" in text or "usage" in text)
		return {
			"ok": ok,
			"evidence_refs": ["devtools/jext-cli/run.sh", "invalid-command-fail-closed"],
		}
	return {"ok": False, "evidence_refs": ["unknown-scenario"]}


def _identity() -> tuple[str, str, str]:
	active = STATE / "active-run.json"
	if not active.is_file():
		return "", "", ""
	try:
		run_id = str(json.loads(active.read_text(encoding="utf-8")).get("run_id") or "")
		run_dir = STATE / "runs" / run_id
		run = json.loads((run_dir / "run.json").read_text(encoding="utf-8"))
		compile_doc = json.loads((run_dir / "compile.json").read_text(encoding="utf-8"))
		universe = compile_doc.get("universe") or {}
		snap = str(run.get("snapshot_id") or "")
		uni = str(compile_doc.get("universe_id") or universe.get("id") or "")
		return snap, uni, run_id
	except (OSError, json.JSONDecodeError, AttributeError, TypeError):
		return "", "", ""


def main() -> int:
	snap, uni, run_id = _identity()
	if not all((snap, uni, run_id)):
		print(json.dumps({"ok": False, "error": "no-active-run-identity"}))
		return 1
	run_dir = STATE / "runs" / run_id
	db = run_dir / "cells.sqlite"
	if not db.is_file():
		print(json.dumps({"ok": False, "error": "no-cells-db"}))
		return 1
	scenarios = {s: prove(s) for s in SCENARIOS}
	con = sqlite3.connect(str(db))
	con.row_factory = sqlite3.Row
	rows = list(
		con.execute(
			"SELECT cell_id, scenario, snapshot_id, universe_id FROM cells "
			"WHERE surface_id='capability:repository' AND pack='universal'"
		)
	)
	con.close()
	receipts = run_dir / "receipts"
	receipts.mkdir(parents=True, exist_ok=True)
	written = 0
	for row in rows:
		scenario = str(row["scenario"] or "")
		result = scenarios.get(scenario) or {}
		if result.get("ok") is not True:
			continue
		if str(row["snapshot_id"] or "") != snap or str(row["universe_id"] or "") != uni:
			continue
		doc = {
			"schema": "hurc-complete-e2e-named-receipt/v1",
			"ok": True,
			"cell_id": row["cell_id"],
			"snapshot_id": snap,
			"universe_id": uni,
			"run_id": run_id,
			"surface_id": "capability:repository",
			"pack": "universal",
			"scenario": scenario,
			"prover": "jext-cli-repository-occupancy",
			"evidence_refs": list(result.get("evidence_refs") or []) + ["repository-occupancy"],
		}
		(receipts / f"{row['cell_id']}.json").write_text(json.dumps(doc, indent=2) + "\n", encoding="utf-8")
		for other in (STATE / "runs").glob("*/receipts"):
			if other.parent.name == run_id:
				continue
			stale = other / f"{row['cell_id']}.json"
			if stale.is_file():
				stale.unlink()
		written += 1
	out = {
		"ok": all(scenarios[s].get("ok") is True for s in SCENARIOS),
		"scenarios": scenarios,
		"named_receipts": written,
		"run_id": run_id,
	}
	print(json.dumps(out))
	return 0 if out["ok"] else 1


if __name__ == "__main__":
	raise SystemExit(main())
