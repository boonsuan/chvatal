# Palomar submission preparation

This repository provides the materials for submitting
[boonsuan/chvatal](https://github.com/boonsuan/chvatal) to Palomar. The mathematical
proof is due to Fan Chang, Hong Liu, and Miao Liu. I used GPT-6 through Codex to
formalize it; I made no mathematical contribution. The local checks recorded
here do not constitute submission or registration.

The proposed registry title and public description are in
[formalization.yaml](../formalization.yaml). They explicitly identify the work
as a formalization of the authors' proof and disclose my role and GPT-6's role.

## The statement of record

[Palomar's submission instructions](https://palomar-registry.org/how-to-submit)
require an independent, readable Challenge and a separately checked Solution.
Our [Challenge](../Challenge.lean) imports only mathlib and gives concrete
mathematical definitions. Its nine deliberate theorem holes mark the claims to
be checked; none occurs in a definition. The [Solution](../Solution.lean) imports
the substantive library and proves the expanded finite-set theorem. It never
imports the Challenge. The other selected declarations are the library's
proved theorems, imported by Solution.

[comparator.json](../comparator.json) selects exactly these nine declarations:

| Paper | Statement of record |
|---|---|
| Theorem 1.1 | `ChvatalSubmission.chvatal` |
| Theorem 1.2 | `Chvatal.sharp_correlation` |
| Corollary 1.3 | `Chvatal.antipodal_correlation` |
| Theorem 1.4 | `Chvatal.two_spectral_le_quadratic_covariance` |
| Proposition 5.1: equality | `Chvatal.andFunction_sharp` |
| Proposition 5.1: optimal coefficient | `Chvatal.quarter_coefficient_optimal` |
| Remark 5.2 | `Chvatal.and_or_two_example` |
| Proposition 5.3: ordered coefficients and both bounds | `Chvatal.kleitman_weighted_bound` |
| Proposition 5.3: maximum attainment | `Chvatal.exists_largest_weighted_intersecting_star` |

The supporting theorems, lemmas, equations, and signed-Boolean formulation are
also proved in the library and covered by the axiom audit. They are mapped in
[PaperMap.md](PaperMap.md), but are not additional selected Comparator claims.
The compared main star theorem expands heredity and intersection using ordinary
finite-set notation so a reader can inspect its quantifiers directly.

The configuration permits only `propext`, `Classical.choice`, and `Quot.sound`,
and requires NanoDa. Comparator checks the statements' dependencies as well as
the theorem types, so the concrete definitions cannot silently change between
Challenge and Solution. This follows Palomar's
[mechanical requirements](https://github.com/PalomarRegistry/PalomarPolicy/blob/main/CONTRIBUTING.md).

## Reproduce the checks

The project remains on Lean and mathlib **4.33.1**. The source manifest pins every
dependency; [scripts/palomar_tools.json](../scripts/palomar_tools.json) separately
pins the checking tools. [Verification.md](Verification.md) records the exact
setup, observed outcomes, evidence files, and host limitations.

Run from the repository root:

```sh
lake exe cache get
./scripts/verify.sh
bash scripts/palomar_setup.sh
.tools/metadata-venv/bin/python scripts/palomar_metadata.py
```

The first verification command builds the proved library and Solution with
warnings treated as failures, performs the transitive axiom audit, and runs
linters. Challenge is intentionally outside the default build because its
statement-only holes produce expected warnings. To inspect it independently:

```sh
lake env lean Challenge.lean
```

On macOS, run the documented Comparator development mode:

```sh
bash scripts/palomar_check.sh --development-unsandboxed
```

This runs actual statement/proof comparison, Lean kernel replay, and the
independent NanoDa kernel. It uses upstream's development adapter because
Linux process confinement is unavailable on macOS. The recorded result therefore
does **not** claim that Palomar's sandboxed service has run. On a supported Linux
host, use the confined command described in [Verification.md](Verification.md).
Local commands do not send a submission or the formalization to Palomar.

The metadata validator uses the pinned official schema and intake contract.
It checks structured metadata, comparator policy, and toolchain eligibility;
it does not perform the registry's mathematical editorial review.

## Review and submission

1. Read the first-person account and attribution in [README.md](../README.md)
   and the proposed public title/description in [formalization.yaml](../formalization.yaml).
2. Inspect [Challenge.lean](../Challenge.lean), especially nonempty ground types,
   intersection including self-pairs, Boolean values, uniform normalization,
   the empty-index convention, and the direction of decreasing weights.
3. Inspect [Verification.md](Verification.md) and the recorded local check reports.
4. Commit and push the desired snapshot to
   [boonsuan/chvatal](https://github.com/boonsuan/chvatal). Obtain its full
   40-character commit SHA with `git rev-parse HEAD` and confirm that the commit
   is available in the public repository.
5. Submit that repository and exact commit with the default project root,
   `comparator.json`, and `formalization.yaml`. The repository contains the
   substantive formalization, so my authorization role is its maintainer.
   Review the eventual private report before choosing whether to register.

These steps follow the [current submission process](https://palomar-registry.org/how-to-submit).
The maintainer completes the final submission in the browser. A local
verification pass does not assert a Palomar review outcome.

## What the checks establish

The local evidence distinguishes compilation, axiom auditing, statement
comparison, Lean replay, and NanoDa acceptance. The documentation and source
correspondence review were generated by GPT-6; no independent human mathematical
review is claimed. Kernel verification concerns the formal statements. Reading
those statements against the authors' paper remains necessary to assess the
translation's fidelity. This distinction is central to
[Tao's announcement](https://terrytao.wordpress.com/2026/08/18/palomar-a-registry-of-lean-verified-mathematics/)
and [Palomar's account of its limits](https://palomar-registry.org/about).

The source authors are credited for the mathematics, not represented as having
reviewed or endorsed this repository. Existing library and tool dependencies
retain their own licenses. The bundled formalization schema has its separate
license in [schema/](schema/).
