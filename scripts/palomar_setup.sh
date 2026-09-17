#!/usr/bin/env bash
# Build exactly pinned verification tools. Prerequisites must already exist.
# Optional PALOMAR_COMPARATOR_LAKE selects a standalone checker-only Lake binary.
set -euo pipefail
palomar_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$palomar_root"
mkdir -p .tools
exec > >(tee .tools/palomar-setup.log) 2>&1
python3 -c 'import sys; assert sys.version_info >= (3, 11), "Python 3.11 or newer is required"'
python3 - "$palomar_root" <<'PY'
from pathlib import Path
import json, subprocess, sys
root = Path(sys.argv[1]); pins = json.loads((root/'scripts/palomar_tools.json').read_text())
if (root/'lean-toolchain').read_text().strip() != pins['project_toolchain']:
    raise SystemExit('Project toolchain differs from the pinned verifier configuration.')
for name, spec in pins['repositories'].items():
    path = root/'.tools'/name
    if not path.exists():
        subprocess.run(['git','clone','--filter=blob:none','--no-checkout',spec['url'],str(path)],check=True)
        subprocess.run(['git','-C',str(path),'checkout','--detach',spec['commit']],check=True)
    remote = subprocess.check_output(['git','-C',str(path),'remote','get-url','origin'],text=True).strip()
    if remote != spec['url']:
        raise SystemExit('Unexpected tool remote: '+str(path))
    dirty = subprocess.check_output(['git','-C',str(path),'status','--porcelain','--untracked-files=no'],text=True)
    if dirty:
        raise SystemExit('Refusing to overwrite modified tool sources: '+str(path))
    head = subprocess.check_output(['git','-C',str(path),'rev-parse','HEAD'],text=True).strip()
    if head != spec['commit']:
        subprocess.run(['git','-C',str(path),'fetch','--depth','1','origin',spec['commit']],check=True)
        subprocess.run(['git','-C',str(path),'checkout','--detach',spec['commit']],check=True)
    print(name, spec['commit'], flush=True)
PY
palomar_project_toolchain="$(python3 -c 'import json; print(json.load(open("scripts/palomar_tools.json"))["project_toolchain"])')"
palomar_comparator_toolchain="$(python3 -c 'import json; print(json.load(open("scripts/palomar_tools.json"))["comparator_toolchain"])')"
palomar_require_installed_toolchain() {
  if ! elan toolchain list | awk '{print $1}' | grep -Fxq -- "$1"; then
    echo "Required compiler is not installed: $1" >&2
    echo 'Install it separately or use the scoped macOS bootstrap for checker prerequisites.' >&2
    exit 2
  fi
}
palomar_require_installed_toolchain "$palomar_project_toolchain"
palomar_project_lake="$(ELAN_TOOLCHAIN="$palomar_project_toolchain" elan which lake)"
if [[ -n "${PALOMAR_COMPARATOR_LAKE:-}" ]]; then
  palomar_comparator_lake="$PALOMAR_COMPARATOR_LAKE"
elif [[ -x "$palomar_root/.tools/lean-4.34.0-rc1-darwin_aarch64/bin/lake" ]]; then
  palomar_comparator_lake="$palomar_root/.tools/lean-4.34.0-rc1-darwin_aarch64/bin/lake"
else
  palomar_require_installed_toolchain "$palomar_comparator_toolchain"
  palomar_comparator_lake="$(ELAN_TOOLCHAIN="$palomar_comparator_toolchain" elan which lake)"
fi
palomar_project_version="$("$palomar_project_lake" --version)"
palomar_comparator_version="$("$palomar_comparator_lake" --version)"
printf '%s\n' "$palomar_project_version" "$palomar_comparator_version"
[[ "$palomar_project_version" == *"(Lean version ${palomar_project_toolchain##*:v})"* ]] || {
  echo 'Project Lake compiler version mismatch.' >&2; exit 2;
}
[[ "$palomar_comparator_version" == *"(Lean version ${palomar_comparator_toolchain##*:v})"* ]] || {
  echo 'Comparator Lake compiler version mismatch.' >&2; exit 2;
}
if [[ -x "$palomar_root/.tools/rust/bin/cargo" ]]; then
  export PATH="$palomar_root/.tools/rust/bin:$PATH"
fi
command -v cargo >/dev/null || { echo 'Rust cargo is required (pinned version 1.90.0).' >&2; exit 2; }
palomar_rust_version="$(python3 -c 'import json; print(json.load(open("scripts/palomar_tools.json"))["rust_version"])')"
palomar_rust_observed="$(rustc --version)"
palomar_cargo_observed="$(cargo --version)"
printf '%s\n' "$palomar_rust_observed" "$palomar_cargo_observed"
[[ "$palomar_rust_observed" == "rustc $palomar_rust_version "* && "$palomar_cargo_observed" == "cargo $palomar_rust_version "* ]] || {
  echo 'Rust/Cargo version mismatch; use the version in scripts/palomar_tools.json.' >&2; exit 2;
}
export CARGO_HOME="$palomar_root/.tools/cargo-home"
(
  cd .tools/comparator
  unset LEAN_PATH LEAN_SYSROOT
  ELAN_TOOLCHAIN="$palomar_comparator_toolchain" "$palomar_comparator_lake" build comparator
)
(
  cd .tools/lean4export
  unset LEAN_PATH LEAN_SYSROOT
  ELAN_TOOLCHAIN="$palomar_project_toolchain" "$palomar_project_lake" build lean4export
)
cargo build --release --locked --manifest-path .tools/nanoda/Cargo.toml
if [[ "$(uname -s)" == Linux ]]; then
  command -v go >/dev/null || { echo 'Go is required to build Landrun on Linux.' >&2; exit 2; }
  palomar_go_version="$(python3 -c 'import json; print(json.load(open("scripts/palomar_tools.json"))["go_version"])')"
  palomar_go_observed="$(go version)"
  printf '%s\n' "$palomar_go_observed"
  [[ "$palomar_go_observed" == "go version go$palomar_go_version "* ]] || {
    echo 'Go version mismatch; use the version in scripts/palomar_tools.json.' >&2; exit 2;
  }
  export GOPATH="$palomar_root/.tools/go"
  export GOCACHE="$palomar_root/.tools/go/cache"
  export GOBIN="$palomar_root/.tools/go/bin"
  palomar_landrun_spec="$(python3 -c 'import json; p=json.load(open("scripts/palomar_tools.json"))["landrun"]; print(p["module"]+"@"+p["commit"])')"
  CGO_ENABLED=0 go install "$palomar_landrun_spec"
fi
python3 - "$palomar_root" "$palomar_project_lake" "$palomar_comparator_lake" <<'PY'
from pathlib import Path
import hashlib,json,platform,subprocess,sys
root=Path(sys.argv[1]); pins=json.loads((root/'scripts/palomar_tools.json').read_text())
paths={'comparator':root/'.tools/comparator/.lake/build/bin/comparator',
       'lean4export':root/'.tools/lean4export/.lake/build/bin/lean4export',
       'nanoda':root/'.tools/nanoda/target/release/nanoda_bin'}
if platform.system()=='Linux':paths['landrun']=root/'.tools/go/bin/landrun'
report={'pins':pins,'host':platform.platform(),'project_lake':subprocess.check_output([sys.argv[2],'--version'],text=True).strip(),
        'comparator_lake':subprocess.check_output([sys.argv[3],'--version'],text=True).strip(),
        'rustc':subprocess.check_output(['rustc','--version'],text=True).strip(),'binaries':{}}
for name,path in paths.items():
 with path.open('rb') as stream:digest=hashlib.file_digest(stream,'sha256').hexdigest()
 report['binaries'][name]={'path':str(path.relative_to(root)),'sha256':digest}
(root/'.tools/palomar-tool-build.json').write_text(json.dumps(report,indent=2)+'\n')
print('Pinned checker tools built; manifest: .tools/palomar-tool-build.json')
PY
python3 -m venv .tools/metadata-venv
.tools/metadata-venv/bin/python -m pip install --disable-pip-version-check -r requirements-checks.txt
echo 'Metadata dependencies ready: .tools/metadata-venv/bin/python scripts/palomar_metadata.py'
