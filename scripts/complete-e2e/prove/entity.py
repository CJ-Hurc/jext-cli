#!/usr/bin/env python3
"""Occupancy entrypoint auto-run by complete-e2e (_ensure_product_occupancy).

Delegates to repository.py so universal missing-env/invalid-config receipts
survive the prove-dir stale-receipt clear.
"""
from __future__ import annotations

import importlib.util
from pathlib import Path


def main() -> int:
	path = Path(__file__).with_name("repository.py")
	spec = importlib.util.spec_from_file_location("jext_cli_repository_prove", path)
	if spec is None or spec.loader is None:
		print("{" + '"ok": false, "error": "repository.py missing"' + "}")
		return 1
	mod = importlib.util.module_from_spec(spec)
	spec.loader.exec_module(mod)
	return int(mod.main())


if __name__ == "__main__":
	raise SystemExit(main())
