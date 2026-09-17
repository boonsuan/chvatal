/-
Copyright (c) 2026 Chvatal formalization contributors. All rights reserved.
Released under MIT license as described in the file LICENSE.
Authors: Chvatal formalization contributors
-/
import Solution
import Lean.Elab.Command
import Lean.Util.CollectAxioms

/-!
# Independent statement and axiom checks

This file is not imported by the mathematical library. It restates Chvátal's
conjecture using only standard finite sets and checks every exported theorem in
the `Chvatal` and `ChvatalSubmission` namespaces for transitive axiom dependencies. Only Lean's standard
`propext`, `Classical.choice`, and `Quot.sound` are permitted.
-/

example {ι : Type*} [Finite ι] [DecidableEq ι] [Nonempty ι]
    (D A : Finset (Finset ι))
    (hD : ∀ s ∈ D, ∀ t, t ⊆ s → t ∈ D)
    (hAD : A ⊆ D)
    (hA : ∀ s ∈ A, ∀ t ∈ A, (s ∩ t).Nonempty) :
    ∃ i : ι, A.card ≤ (D.filter (fun s => i ∈ s)).card := by
  apply Chvatal.chvatal (D := D) (A := A) ?_ hAD ?_
  · intro t s hts hs
    exact hD t hs s hts
  · intro s hs t ht
    exact (hA s hs t ht).not_disjoint

/-- Fail if any exported Chvatal theorem depends on an axiom beyond the standard three. -/
elab "audit_chvatal_axioms" : command => do
  let env ← Lean.getEnv
  let names := env.constants.fold (init := #[]) fun names name info =>
    if ((`Chvatal).isPrefixOf name || (`ChvatalSubmission).isPrefixOf name) &&
        info matches .thmInfo _ then names.push name else names
  if names.isEmpty then
    throwError "No Chvatal theorems found; check the imports and namespace filter."
  let permitted := #[``propext, ``Classical.choice, ``Quot.sound]
  for name in names do
    let axioms ← Lean.collectAxioms name
    let unexpected := axioms.filter fun ax => !permitted.contains ax
    unless unexpected.isEmpty do
      throwError "{name} uses unexpected axioms: {unexpected.toList}"
  Lean.logInfo m!"Audited {names.size} Chvatal theorems: only standard Lean axioms."

audit_chvatal_axioms

#print axioms Chvatal.chvatal
#print axioms Chvatal.sharp_correlation
#print axioms Chvatal.antipodal_correlation
#print axioms Chvatal.two_spectral_le_quadratic_covariance
#print axioms Chvatal.andFunction_sharp
#print axioms Chvatal.quarter_coefficient_optimal

#print axioms Chvatal.kleitman_weighted_bound
#print axioms Chvatal.exists_largest_weighted_intersecting_star

#print axioms ChvatalSubmission.chvatal
