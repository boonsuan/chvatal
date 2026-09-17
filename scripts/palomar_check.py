#!/usr/bin/env python3
"""Compare the independent statement and recheck its proof with Lean and NanoDa.

Linux uses the pinned Palomar Landrun argument adapter and systemd confinement.
macOS requires the explicit --development-unsandboxed switch; only the upstream
process-sandbox adapter is substituted, and both actual kernels still run.
This is local verification, not the Palomar service's full intake or review.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import platform
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parent.parent


def digest(path: Path) -> str:
    """Hash a pinned tool or a compared source file without loading it all at once."""
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def source_snapshot() -> dict[str, str]:
    """Bind the comparison to every project proof source and build configuration."""
    paths = [ROOT/name for name in (
        'Challenge.lean', 'Solution.lean', 'Chvatal.lean', 'comparator.json',
        'lean-toolchain', 'lakefile.toml', 'lake-manifest.json',
        'scripts/palomar_tools.json',
    )]
    paths.extend(sorted((ROOT/'Chvatal').rglob('*.lean')))
    return {str(path.relative_to(ROOT)):digest(path) for path in paths}


def save_evidence(report: dict, output: str, manifest: dict) -> None:
    """Overwrite both success and failure evidence so a failed rerun is never green."""
    (ROOT/'.tools').mkdir(exist_ok=True)
    logs = ROOT/'logs'
    logs.mkdir(exist_ok=True)
    report_path = ROOT/'.tools'/('palomar-comparator-'+report['mode']+'.json')
    serialized = json.dumps(report,indent=2)+'\n'
    report_path.write_text(serialized)
    (logs/'palomar-check.json').write_text(serialized)
    (logs/'palomar-tools.json').write_text(json.dumps(manifest,indent=2)+'\n')
    (logs/'palomar-output.log').write_text(output)
    accepted = lambda key: 'accepted' if report.get(key) else 'not accepted'
    summary = [
        'Mode: '+report['mode'],
        'Scope: local Comparator comparison and actual Lean/NanoDa checking.',
        'This is not Palomar intake, editorial review, or registration.',
        'Status: '+report['status'],
        'Started UTC: '+report['started_utc'],
        'Statement comparison and complete Comparator result: '+accepted('comparator_accepted'),
        'NanoDa independent kernel: '+accepted('nanoda_accepted'),
        'Lean default kernel replay: '+accepted('lean_replay_accepted'),
        'All project proof/build source hashes unchanged: '+str(report.get('compared_sources_unchanged',False)),
        'Source manifest SHA256: '+report.get('source_manifest_sha256','unavailable'),
        'Exit code: '+str(report.get('exit_code','pending')),
        'Elapsed seconds: '+str(report.get('elapsed_seconds','pending')),
        'Raw checker output: logs/palomar-output.log',
        'Tool revisions and binary hashes: logs/palomar-tools.json',
    ]
    if report.get('error'):
        summary.append('Error: '+report['error'])
    (logs/'palomar-check.log').write_text('\n'.join(summary)+'\n')


def perform_check(args: argparse.Namespace, report: dict, manifest: dict) -> int:
    """Validate tools, compare statements, and run both genuine kernels."""
    system = platform.system()
    if args.timeout < 1:
        raise ValueError('--timeout must be positive')
    if args.development_unsandboxed and system != 'Darwin':
        raise ValueError('the development adapter is restricted to macOS; Linux must use confinement')
    if system != 'Linux' and not args.development_unsandboxed:
        raise ValueError('Linux confinement is unavailable; macOS requires --development-unsandboxed')
    pins = json.loads((ROOT/'scripts/palomar_tools.json').read_text())
    manifest.update(json.loads((ROOT/'.tools/palomar-tool-build.json').read_text()))
    if manifest['pins'] != pins:
        raise RuntimeError('Tool build manifest does not match the committed pins; rerun setup.')
    if (ROOT/'lean-toolchain').read_text().strip() != pins['project_toolchain']:
        raise RuntimeError('Project Lean toolchain differs from the checker configuration.')
    for name, spec in pins['repositories'].items():
        path = ROOT/'.tools'/name
        head = subprocess.check_output(['git','-C',str(path),'rev-parse','HEAD'],text=True).strip()
        dirty = subprocess.check_output(['git','-C',str(path),'status','--porcelain','--untracked-files=no'],text=True)
        if head != spec['commit'] or dirty:
            raise RuntimeError('Tool source revision or integrity mismatch: '+name)
    for name, binary in manifest['binaries'].items():
        if digest(ROOT/binary['path']) != binary['sha256']:
            raise RuntimeError('Tool binary changed after setup: '+name)
    config = json.loads((ROOT/'comparator.json').read_text())
    if config.get('enable_nanoda') is not True:
        raise RuntimeError('NanoDa must remain enabled for this local checking script.')
    if set(config['permitted_axioms']) != {'propext','Quot.sound','Classical.choice'}:
        raise RuntimeError('Unexpected axiom policy.')

    environment = os.environ.copy()
    for name in ('LEAN_PATH','LEAN_SYSROOT','PALOMAR_PROTECTED_CHALLENGE_MODULE','LAKE_PKG_URL_MAP'):
        environment.pop(name, None)
    environment['ELAN_TOOLCHAIN'] = pins['project_toolchain']
    lake = subprocess.check_output(['elan','which','lake'],env=environment,text=True).strip()
    # Inner `lake`/`lean` invocations must use the submitted compiler, not the
    # separate compiler that was needed to build Comparator itself.
    environment['PATH'] = str(Path(lake).parent) + os.pathsep + environment['PATH']
    environment.update({
        'COMPARATOR_LEAN4EXPORT': str(ROOT/manifest['binaries']['lean4export']['path']),
        'COMPARATOR_NANODA': str(ROOT/manifest['binaries']['nanoda']['path']),
        'LEAN_ABORT_ON_PANIC': '1',
        'GIT_CONFIG_GLOBAL': '/dev/null',
        'GIT_CONFIG_NOSYSTEM': '1',
        'GIT_TERMINAL_PROMPT': '0',
    })
    command = [lake, 'env', str(ROOT/manifest['binaries']['comparator']['path']), str(ROOT/'comparator.json')]
    if args.development_unsandboxed:
        environment['COMPARATOR_LANDRUN'] = str(ROOT/'.tools/comparator/scripts/fake-landrun.sh')
        print('MACOS DEVELOPMENT CHECK: no process sandbox; genuine Comparator, Lean replay, and NanoDa run.',flush=True)
    else:
        if os.getuid() == 0:
            raise RuntimeError('Run the verifier as an unprivileged user.')
        environment['COMPARATOR_LANDRUN'] = str(ROOT/'.tools/palomar-submission/scripts/landrun_passthrough.py')
        environment['PALOMAR_LANDRUN_REAL'] = str(ROOT/manifest['binaries']['landrun']['path'])
        # Reuse the exact pinned verifier's fail-closed system/user manager probe,
        # argument preservation, environment allowlist, and AF_UNIX restriction.
        sys.path.insert(0, str(ROOT/'.tools/palomar-submission'))
        from scripts.verify_submission import systemd_command
        command = systemd_command(command, cwd=ROOT, environment=environment, timeout=args.timeout)


    report['command'] = command
    sources = source_snapshot()
    report['source_sha256'] = sources
    report['source_manifest_sha256'] = hashlib.sha256(
        json.dumps(sources,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    report['tool_manifest_sha256'] = digest(ROOT/'.tools/palomar-tool-build.json')
    log = ROOT/'.tools'/('palomar-comparator-'+report['mode']+'.log')
    report['log'] = str(log.relative_to(ROOT))
    save_evidence(report, 'Tool checks passed; Comparator is running.\n', manifest)
    with log.open('w') as stream:
        stream.write('Mode: '+report['mode']+'\n')
        stream.flush()
        process = subprocess.Popen(command,cwd=ROOT,env=environment,stdout=stream,
                                   stderr=subprocess.STDOUT,start_new_session=True)
        try:
            report['exit_code'] = process.wait(timeout=args.timeout)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid, signal.SIGTERM)
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
            report['exit_code'] = 124
            report['error'] = 'Checker timed out.'
    output = log.read_text()
    print(output,end='',flush=True)
    report['nanoda_accepted'] = 'nanoda kernel accepts the solution' in output
    report['lean_replay_accepted'] = 'Lean default kernel accepts the solution' in output
    report['comparator_accepted'] = 'Your solution is okay!' in output
    report['compared_sources_unchanged'] = source_snapshot() == sources
    passed = (report['exit_code']==0 and report['nanoda_accepted'] and
              report['lean_replay_accepted'] and report['comparator_accepted'] and
              report['compared_sources_unchanged'])
    return 0 if passed else 1


def main() -> int:
    """Persist the true outcome of every attempted local verification."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--development-unsandboxed',action='store_true',
                        help='macOS only: explicitly use upstream fake-landrun, retaining both kernels')
    parser.add_argument('--timeout',type=int,default=3600,help='maximum checker seconds (default 3600)')
    args = parser.parse_args()
    started = time.monotonic()
    report = {
        'mode':'macos-development-unsandboxed' if args.development_unsandboxed else 'linux-confined',
        'scope':'Local Comparator and genuine Lean/NanoDa checking; not Palomar intake or editorial review.',
        'started_utc':dt.datetime.now(dt.timezone.utc).isoformat(),
        'status':'running',
    }
    manifest: dict = {}
    save_evidence(report,'Checking local verification prerequisites.\n',manifest)
    try:
        code = perform_check(args,report,manifest)
    except (OSError,ValueError,KeyError,RuntimeError,subprocess.CalledProcessError) as error:
        code = 2
        report['exit_code'] = code
        report['error'] = str(error)
        print('Palomar local check error: '+str(error),file=sys.stderr)
    report['status'] = 'passed' if code==0 else 'failed'
    report['elapsed_seconds'] = round(time.monotonic()-started,3)
    log = ROOT/report['log'] if 'log' in report else None
    output = log.read_text() if log and log.exists() else 'Checker did not run.\n'
    if report.get('error'):
        output += 'Local checking error: '+report['error']+'\n'
    save_evidence(report,output,manifest)
    print('Local check '+report['status']+'; report: logs/palomar-check.json',flush=True)
    return code


if __name__ == '__main__':
    raise SystemExit(main())
