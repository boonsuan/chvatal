# Reproducing the local checks

The repository contains the mathematical development and a separate, short
Palomar statement in `Challenge.lean`. `Solution.lean` proves the declarations
listed in `comparator.json`. Deliberate `sorry` placeholders in the Challenge
describe the independent statement; they are not part of the Solution's proofs.

## Recorded local results — 17 September 2026

| Check | Result |
| --- | --- |
| `bash scripts/verify.sh` | Passed: build, `Chvatal` and `Solution` linters, and the axiom audit of all 369 exported project theorems |
| Official v0.4 metadata schema and pinned Palomar intake contract | Passed |
| Palomar Comparator-configuration and toolchain policy | Passed |
| Comparator statement and axiom comparison | Accepted all 9 selected theorems |
| Lean kernel replay | Accepted |
| Independent NanoDa kernel | Accepted |
| Proof/build source hashes before and after comparison | Unchanged |

The comparison ran at `2026-09-17T03:49:04Z` and completed in 33.713 seconds.
It used the explicitly selected **unsandboxed macOS development mode** described
below. It is local verification, not Palomar's sandboxed service check or
editorial review. The Challenge emitted exactly its nine intentional `sorry`
warnings; the Solution build emitted no warnings.

The [machine-readable result](../logs/palomar-check.json),
[checker output](../logs/palomar-output.log),
[tool build record](../logs/palomar-tools.json), and
[metadata check output](../logs/palomar-metadata.log) preserve the evidence.
The comparison's source-manifest SHA-256 is
`d65cb0fdadc6a67a2153abfc55845ed27722f9a3f3540eae565c76a5402887ad`.
These records describe the checked files, not future edits.

## Build and axiom audit

Run the ordinary build, linters, and axiom audit with:

```sh
lake exe cache get
bash scripts/verify.sh
```

The only permitted axioms are `propext`, `Quot.sound`, and `Classical.choice`.
The formalization must not depend on `sorryAx`, `Lean.ofReduceBool`, or a custom
axiom. Axiom checking alone does not establish that the formal statements
accurately represent the paper; readers should inspect the statements too.

## Pinned checker tools

[`scripts/palomar_tools.json`](../scripts/palomar_tools.json) fixes the sources
used for local reproduction. The Comparator, NanoDa, and Landrun revisions
match the [Palomar verification profile](https://github.com/PalomarRegistry/PalomarSubmission/blob/ec6064aea91e2f99187f3f46a2652e4d977ce755/verification-profile.json)
consulted on 17 September 2026. The schema and policy revisions are pinned there
as well. Updating these pins is a deliberate maintenance step.

The project uses Lean 4.33.1 throughout. The verifier's current
[release compatibility rule](https://github.com/PalomarRegistry/PalomarSubmission/blob/ec6064aea91e2f99187f3f46a2652e4d977ce755/scripts/verify_submission.py)
permits the Lean 4.33.0 exporter source to be rebuilt with Lean 4.33.1 when an
exact exporter patch tag is absent. The exporter is built with 4.33.1 here.
Comparator itself requires a separate Lean 4.34.0-rc1 compiler; that does not
change the compiler used for the mathematical project.

Setup requires Git, Python 3.11 or newer, the project and Comparator Lean
toolchains, and Rust/Cargo 1.90.0. Linux additionally needs Go 1.24.0 and a
working unprivileged systemd/Landrun environment. Build the tools with:

```sh
bash scripts/palomar_setup.sh
```

On Apple Silicon macOS, `bash scripts/palomar_bootstrap_macos.sh` can first
download the pinned Comparator compiler and Rust prerequisites into `.tools/`.
It verifies archive hashes and does not change global compiler defaults.
The project Lean toolchain still needs to be installed through elan.

Setup fetches public upstream tool sources and Python dependencies; it sends
no project sources or metadata to a submission service. It refuses modified
tool checkouts. Build products, package caches, and downloaded prerequisites
remain under the ignored `.tools/` directory.

## Metadata and statement comparison

Validate the metadata against both the official schema and Palomar's pinned
intake contract:

```sh
.tools/metadata-venv/bin/python scripts/palomar_metadata.py
```

On a supported Linux host, run the confined comparison:

```sh
bash scripts/palomar_check.sh
```

On macOS, run the explicitly selected development mode:

```sh
bash scripts/palomar_check.sh --development-unsandboxed
```

The macOS command uses the unmodified adapter documented in
[Comparator's development instructions](https://github.com/leanprover/comparator/blob/575674928e239f5bc452aab72d1dd7b0f1326494/README.md#development).
There is no process sandbox in this mode. Comparator still compares the
advertised statements, checks allowed axioms, replays the exported proof
through Lean's kernel, and runs the genuine independent NanoDa kernel.
This local development result is not the registry's sandboxed verification.

Each attempted comparison writes its actual result to
`logs/palomar-check.json`, a concise account to `logs/palomar-check.log`, raw
checker output to `logs/palomar-output.log`, and tool revisions and binary
hashes to `logs/palomar-tools.json`. The result also records source hashes and
requires that the proof/build inputs remain unchanged during the check.
A failed rerun replaces the previous success evidence.

The metadata check and local comparison do not perform Palomar's editorial
review, check authorization to submit, register an entry, or publish anything.
The eventual registry check must run against an immutable public repository
commit, after the maintainer chooses to publish and submit it.
