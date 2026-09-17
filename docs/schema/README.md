# Metadata schema

`formalization.v0.4.schema.json` is the unmodified upstream
[v0.4 schema](https://github.com/mathlib-initiative/formalization.yaml/blob/99c678e569c7c4c0772db297c5ddd5e4c9b6322e/schema/v0.4.schema.json),
at commit `99c678e569c7c4c0772db297c5ddd5e4c9b6322e`.
Its SHA-256 is `25ff6b25ca4511635aff4443cf20480c15e59dddf19591c730950b442ea54fce`.
`LICENSE.formalization-schema` preserves its upstream Apache-2.0 license;
the project's MIT license does not replace this license.

After `bash scripts/palomar_setup.sh`, run from the project root:

```sh
.tools/metadata-venv/bin/python scripts/palomar_metadata.py
```

This performs both JSON Schema validation and the actual metadata check from
the pinned PalomarSubmission source. The latter checks required disclosures,
recognized classifications, structured authorship, and source relationships.
It reads local files only. It does not check the truth of the disclosures,
contact named people, perform editorial review, or submit the project.

The command also applies Palomar's own local checks to `comparator.json` and
the `lean-toolchain` version.

The schema, policy, and verifier revisions are recorded in
[`scripts/palomar_tools.json`](../../scripts/palomar_tools.json).
The validator checks the schema digest and refuses changed verifier sources.
