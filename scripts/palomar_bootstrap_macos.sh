#!/usr/bin/env bash
# Explicit, local-only prerequisite bootstrap for the Apple Silicon checker host.
# It never registers an elan toolchain or modifies global Rust/Lean defaults.
set -euo pipefail
palomar_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
[[ "$(uname -s)" == Darwin && "$(uname -m)" == arm64 ]] || {
  echo 'This bootstrap supports Apple Silicon macOS only.' >&2; exit 2;
}
python3 - "$palomar_root" <<'PY'
from pathlib import Path
import hashlib, json, subprocess, sys, urllib.request
root = Path(sys.argv[1])
tools = root / '.tools'
downloads = tools / 'downloads'
downloads.mkdir(parents=True, exist_ok=True)
pins = json.loads((root / 'scripts/palomar_tools.json').read_text())
for archive in pins['macos_arm64_archives']:
    path = downloads / archive['name']
    if not path.exists():
        print('Downloading', archive['name'], flush=True)
        partial = path.with_name(path.name + '.partial')
        urllib.request.urlretrieve(archive['url'], partial)
        partial.rename(path)
    with path.open('rb') as stream:
        actual = hashlib.file_digest(stream, 'sha256').hexdigest()
    if actual != archive['sha256']:
        raise SystemExit('Checksum mismatch: ' + str(path))
    print('Verified SHA256:', archive['name'], actual, flush=True)
    directory = tools / archive['name'].removesuffix('.tar.zst').removesuffix('.tar.xz')
    if not directory.exists():
        subprocess.run(['tar', '-xf', str(path), '-C', str(tools)], check=True)
    if archive['component'] == 'rust':
        subprocess.run(['bash', str(directory / 'install.sh'),
                        '--prefix=' + str(tools / 'rust'), '--disable-ldconfig'], check=True)
print('Local prerequisites ready; run bash scripts/palomar_setup.sh.', flush=True)
PY
