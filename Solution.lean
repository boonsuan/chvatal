/-
Copyright (c) 2026 Chvatal formalization contributors. All rights reserved.
Released under MIT license as described in the file LICENSE.
Authors: GPT-6 (formalization); Boon Suan Ho (prompting and maintenance)
-/
import Chvatal

/-!
# Proofs of the independent Palomar statements

The mathematics and proof are those of Fan Chang, Hong Liu, and Miao Liu,
arXiv:2609.19123v1. GPT-6 generated this formalization at Boon Suan Ho's request;
Ho claims no mathematical contribution. The principal analytic, sharpness, and
weighted declarations selected in `comparator.json` are provided by `Chvatal`.
The theorem below is the expanded finite-set interface for Theorem 1.1.

This module never imports `Challenge` or its deliberate theorem holes.
-/

namespace ChvatalSubmission

/-- Theorem 1.1 of Chang–Liu–Liu: the proof of the independently stated star bound. -/
theorem chvatal {ι : Type*} [Finite ι] [DecidableEq ι] [Nonempty ι]
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

end ChvatalSubmission
