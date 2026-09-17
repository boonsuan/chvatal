#!/usr/bin/env python3
"""Check metadata against the official schema and pinned Palomar intake contract.

Run with .tools/metadata-venv/bin/python after palomar_setup.sh. All inputs
are local; this script neither sends project metadata nor submits anything.
It checks syntax and structured requirements, not the mathematical account.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import subprocess
import sys

from jsonschema import Draft7Validator

ROOT = Path(__file__).resolve().parent.parent


def main() -> int:
    """Require an unchanged pinned validator before loading its official API."""
    pins = json.loads((ROOT / "scripts/palomar_tools.json").read_text())
    checkout = ROOT / ".tools/palomar-submission"
    revision = subprocess.check_output(
        ["git", "-C", str(checkout), "rev-parse", "HEAD"], text=True
    ).strip()
    changes = subprocess.check_output(
        ["git", "-C", str(checkout), "status", "--porcelain", "--untracked-files=no"],
        text=True,
    )
    if revision != pins["repositories"]["palomar-submission"]["commit"] or changes:
        raise ValueError("The Palomar validator differs from its pinned clean source; rerun setup.")
    schema_bytes = (ROOT / "docs/schema/formalization.v0.4.schema.json").read_bytes()
    if hashlib.sha256(schema_bytes).hexdigest() != pins["formalization_schema"]["sha256"]:
        raise ValueError("The vendored formalization.yaml schema has changed.")

    # Use upstream's actual duplicate-key-safe loader and metadata policy.
    sys.path.insert(0, str(checkout))
    from scripts.submission_contract import load_formalization_metadata
    from scripts.verify_submission import load_comparator_config, supported_toolchain

    metadata = load_formalization_metadata(ROOT / "formalization.yaml")
    schema = json.loads(schema_bytes)
    Draft7Validator.check_schema(schema)
    errors = sorted(Draft7Validator(schema).iter_errors(metadata), key=lambda e: str(e.path))
    if errors:
        for error in errors:
            print(f"{'.'.join(map(str, error.path)) or '$'}: {error.message}", file=sys.stderr)
        return 1
    load_comparator_config(ROOT / "comparator.json")
    supported_toolchain((ROOT / "lean-toolchain").read_text().strip())
    print("Metadata passed the official v0.4 schema and pinned Palomar intake contract.")
    print("Comparator configuration and Lean version passed the pinned Palomar policy.")
    print("Local validation only; no submission, editorial review, or registration performed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError, subprocess.CalledProcessError) as error:
        print(f"Metadata validation failed: {error}", file=sys.stderr)
        raise SystemExit(1) from error
