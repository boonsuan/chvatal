/-
Copyright (c) 2026 Chvatal formalization contributors. All rights reserved.
Released under MIT license as described in the file LICENSE.
Authors: GPT-6 (formalization); Boon Suan Ho (prompting and maintenance)
-/
import Mathlib.Combinatorics.SetFamily.Intersecting
import Mathlib.Data.Fintype.Powerset
import Mathlib.Data.Finset.Max
import Mathlib.Data.Finset.SymmDiff
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Algebra.Ring.Parity

/-!
# A formalization of Chang, Liu, and Liu's proof of Chvátal's conjecture

The mathematical results and proof are due to Fan Chang, Hong Liu, and Miao Liu,
*A proof of Chvátal's conjecture via a sharp correlation inequality*,
arXiv:2609.19123v1. Boon Suan Ho used GPT-6 through Codex to formalize their paper;
he claims no mathematical contribution. This is a machine-checkable companion
to their proof, intended to give additional confidence in its correctness.

This independent statement imports only mathlib. Every definition is concrete.
The intentional theorem holes are the Comparator Challenge convention, not
missing proofs: `Solution` supplies the same declarations without importing this
file. The comparison covers the principal results and sharpness/weighted claims;
the full library also proves the intermediate results listed in docs/PaperMap.md.

Cube points are sets of coordinates. Averages are uniform on all `2^n` points.
Boolean functions take values zero and one; squared flip difference therefore
is the probability of changing. Maxima omit the empty Fourier index via a zero
weight. Real division by zero agrees with the paper's zero-denominator convention.
A coordinate can be selected only when the ground type is nonempty.
-/

open scoped BigOperators symmDiff
noncomputable section

namespace Chvatal

/-- The finite families of subsets used throughout the paper. -/
abbrev Family (ι : Type*) := Finset (Finset ι)

namespace Family
variable {ι : Type*} [DecidableEq ι]

/-- Section 1: a hereditary family is closed under taking subsets. -/
abbrev IsHereditary (D : Family ι) : Prop := IsLowerSet (D : Set (Finset ι))

/-- Intersection includes a member with itself, excluding the empty set. -/
abbrev IsIntersecting (B : Family ι) : Prop := (B : Set (Finset ι)).Intersecting

/-- Section 4: maximal among intersecting families on the full ground type. -/
def IsMaximalIntersecting (B : Family ι) : Prop :=
  B.IsIntersecting ∧ ∀ C : Family ι, C.IsIntersecting → B ⊆ C → B = C

/-- The star of `D` centered at `i`, in Theorem 1.1. -/
def star (D : Family ι) (i : ι) : Family ι := D.filter (i ∈ ·)

/-- The real indicator of a family, used in Sections 4 and 5. -/
def indicator (B : Family ι) (x : Finset ι) : ℝ := if x ∈ B then 1 else 0
end Family

variable {ι : Type*} [Fintype ι] [DecidableEq ι]

/-- Section 2: expectation under the uniform measure on the Boolean cube. -/
def cubeMean (f : Finset ι → ℝ) : ℝ :=
  (∑ x, f x) / Fintype.card (Finset ι)

/-- Section 2: the Walsh character with the paper's negative sign convention. -/
def walsh (S x : Finset ι) : ℝ := (-1 : ℝ) ^ (S ∩ x).card

/-- Section 2: the normalized Fourier coefficient at `S`. -/
def fourier (f : Finset ι → ℝ) (S : Finset ι) : ℝ :=
  cubeMean (fun x => f x * walsh S x)

/-- Section 1: covariance is expectation of the product minus product of expectations. -/
def covariance (f g : Finset ι → ℝ) : ℝ :=
  cubeMean (fun x => f x * g x) - cubeMean f * cubeMean g

/-- Section 1: duality is `1 - f(1-x)`; antipodality means `dual f = f`. -/
def dual (f : Finset ι → ℝ) (x : Finset ι) : ℝ := 1 - f xᶜ

/-- Boolean functions have precisely the permitted values zero and one. -/
def IsBoolean (f : Finset ι → ℝ) : Prop := ∀ x, f x = 0 ∨ f x = 1

/-- Section 2: mean squared change when coordinate `i` is flipped. -/
def influence (f : Finset ι → ℝ) (i : ι) : ℝ :=
  cubeMean (fun x => (f x - f (x ∆ {i})) ^ 2)

/-- Theorem 1.2: maximum influence on a nonempty index; zero on the empty index. -/
def maxInfluence (f : Finset ι → ℝ) (S : Finset ι) : ℝ :=
  if h : S.Nonempty then S.sup' h (influence f) else 0

/-- The left side of Theorem 1.2, denoted `𝒲(f,g)` in Section 5. -/
def spectralWeight (f g : Finset ι → ℝ) : ℝ :=
  ∑ S, fourier g S ^ 2 * maxInfluence f S

/-- The minimum of all coordinate influences in Corollary 1.3. -/
def minInfluence [Nonempty ι] (f : Finset ι → ℝ) : ℝ :=
  Finset.univ.inf' Finset.univ_nonempty (influence f)

/-- Section 5: AND is one exactly when every coordinate is one. -/
def andFunction (x : Finset ι) : ℝ := if x = Finset.univ then 1 else 0

/-- Section 5: OR is the dual of AND. -/
def orFunction : Finset ι → ℝ := dual andFunction

/-- Proposition 5.3: distribute four times the nonconstant Fourier mass by a selector. -/
def spectralWeights (g : Finset ι → ℝ) (select : Finset ι → ι) (i : ι) : ℝ :=
  4 * ∑ S ∈ Finset.univ.erase ∅, if select S = i then fourier g S ^ 2 else 0

/-- Proposition 5.3: select the maximum in the fixed total order.
The arbitrary value at the empty set is never used by `spectralWeights`. -/
def orderedSelector [LinearOrder ι] [Nonempty ι] (S : Finset ι) : ι :=
  if hS : S.Nonempty then S.max' hS else Classical.choice inferInstance

/-- Theorem 1.2, equation (1): the sharp harmonic-mean correlation inequality. -/
theorem sharp_correlation {f g : Finset ι → ℝ} (hf : IsBoolean f) (hmf : Monotone f)
    (hg : IsBoolean g) (hmg : Monotone g) :
    spectralWeight f g ≤
      2 * covariance f g * covariance f (dual g) /
        (covariance f g + covariance f (dual g)) := by
  sorry

/-- Corollary 1.3, equation (2): antipodal covariance is at least one quarter
of minimum influence. -/
theorem antipodal_correlation [Nonempty ι] {f g : Finset ι → ℝ} (hf : IsBoolean f)
    (hmf : Monotone f) (hg : IsBoolean g) (hmg : Monotone g) (hdual : dual g = g) :
    minInfluence f / 4 ≤ covariance f g := by
  sorry

/-- Theorem 1.4, equation (3): the quadratic correlation bound holds for every real parameter. -/
theorem two_spectral_le_quadratic_covariance {f g : Finset ι → ℝ}
    (hf : IsBoolean f) (hmf : Monotone f) (hg : IsBoolean g) (hmg : Monotone g)
    (t : ℝ) :
    2 * (∑ T, ∑ S ∈ Finset.univ.filter (fun S : Finset ι => Odd (S ∩ T).card),
      fourier f S ^ 2 * fourier g T ^ 2) ≤
      t ^ 2 * covariance f g + (1 - t) ^ 2 * covariance f (dual g) := by
  sorry

/-- Proposition 5.1: AND attains equality in Theorem 1.2 for every increasing Boolean function. -/
theorem andFunction_sharp {g : Finset ι → ℝ} (hg : IsBoolean g) (hm : Monotone g) :
    spectralWeight andFunction g =
      2 * covariance andFunction g * covariance andFunction (dual g) /
        (covariance andFunction g + covariance andFunction (dual g)) := by
  sorry

/-- Proposition 5.1: a universal coefficient in Corollary 1.3 cannot exceed one quarter. -/
theorem quarter_coefficient_optimal (c : ℝ)
    (hc : ∀ (f g : Finset (Fin 1) → ℝ), IsBoolean f → Monotone f →
      IsBoolean g → Monotone g → dual g = g →
        c * Finset.univ.inf' Finset.univ_nonempty (influence f) ≤ covariance f g) :
    c ≤ 1 / 4 := by
  sorry

/-- Remark 5.2: the exact AND/OR counterexample to removing antipodality. -/
theorem and_or_two_example :
    covariance (andFunction (ι := Fin 2)) orFunction = 1 / 16 ∧
    covariance (andFunction (ι := Fin 2)) (dual orFunction) = 3 / 16 ∧
    spectralWeight (andFunction (ι := Fin 2)) orFunction = 3 / 32 ∧
    covariance (andFunction (ι := Fin 2)) orFunction <
      spectralWeight (andFunction (ι := Fin 2)) orFunction := by
  sorry

/-- Proposition 5.3, equation (18): ordered spectral coefficients form a probability vector
and bound every nonnegative decreasing weight by a convex combination of star weights. -/
theorem kleitman_weighted_bound [LinearOrder ι] [Nonempty ι] {B : Family ι}
    (hB : B.IsMaximalIntersecting) (ω : Finset ι → ℝ)
    (hω : ∀ x, 0 ≤ ω x) (hanti : Antitone ω) :
    (∀ i, 0 ≤ spectralWeights B.indicator orderedSelector i) ∧
    (∑ i, spectralWeights B.indicator orderedSelector i) = 1 ∧
    (∑ x ∈ B, ω x) ≤
      (∑ i, spectralWeights B.indicator orderedSelector i *
        ∑ x ∈ Family.star Finset.univ i, ω x) ∧
    (∑ i, spectralWeights B.indicator orderedSelector i *
        ∑ x ∈ Family.star Finset.univ i, ω x) ≤
      Finset.univ.sup' Finset.univ_nonempty
        (fun i => ∑ x ∈ Family.star Finset.univ i, ω x) := by
  sorry

/-- Proposition 5.3: one star maximizes a fixed nonnegative decreasing weight
among all intersecting families. -/
theorem exists_largest_weighted_intersecting_star [Nonempty ι]
    (ω : Finset ι → ℝ) (hω : ∀ x, 0 ≤ ω x) (hanti : Antitone ω) :
    ∃ i : ι, (Family.star (Finset.univ : Family ι) i).IsIntersecting ∧
      ∀ A : Family ι, A.IsIntersecting →
        (∑ x ∈ A, ω x) ≤ ∑ x ∈ Family.star Finset.univ i, ω x := by
  sorry

end Chvatal

namespace ChvatalSubmission

/-- Theorem 1.1, expanded using only ordinary finite-set notation: every intersecting
subfamily of a hereditary family is no larger than a star. Nonemptiness of the
ground type states the paper's implicit positive-dimension convention. -/
theorem chvatal {ι : Type*} [Finite ι] [DecidableEq ι] [Nonempty ι]
    (D A : Finset (Finset ι))
    (hD : ∀ s ∈ D, ∀ t, t ⊆ s → t ∈ D)
    (hAD : A ⊆ D)
    (hA : ∀ s ∈ A, ∀ t ∈ A, (s ∩ t).Nonempty) :
    ∃ i : ι, A.card ≤ (D.filter (fun s => i ∈ s)).card := by
  sorry

end ChvatalSubmission
