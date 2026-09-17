#!/usr/bin/env bash
# Run the pinned local Comparator/NanoDa check; never submit or publish.
set -euo pipefail
palomar_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
palomar_python="$palomar_root/.tools/metadata-venv/bin/python"
if [[ ! -x "$palomar_python" ]]; then
  echo 'Checker dependencies are missing; first run bash scripts/palomar_setup.sh.' >&2
  exit 2
fi
exec "$palomar_python" "$palomar_root/scripts/palomar_check.py" "$@"
