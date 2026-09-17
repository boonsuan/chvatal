#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
lake build --wfail
lake env lean scripts/Audit.lean
lake lint
lake env lean --run .lake/packages/batteries/scripts/runLinter.lean --no-build Solution
