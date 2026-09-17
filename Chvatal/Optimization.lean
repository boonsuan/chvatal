/-
Copyright (c) 2026 Chvatal formalization contributors. All rights reserved.
Released under MIT license as described in the file LICENSE.
Authors: Chvatal formalization contributors
-/
import Mathlib.Data.Real.Basic
import Mathlib.Tactic.FieldSimp
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Ring

/-!
# The one-variable optimization in Section 3.3

These elementary real inequalities isolate the optimization used to deduce Theorem 1.2
from Theorem 1.4 of Chang–Liu–Liu, arXiv:2609.19123v1. Real division in Lean assigns
`0 / 0 = 0`, agreeing with the convention in the footnote to Theorem 1.2.
-/

namespace Chvatal

/-- Section 3.3: completing the square in the parameter of Theorem 1.4. -/
theorem quadratic_covariance_identity (a b t : ℝ) (hab : a + b ≠ 0) :
    t ^ 2 * a + (1 - t) ^ 2 * b =
      a * b / (a + b) + (a + b) * (t - b / (a + b)) ^ 2 := by
  field_simp
  ring

/-- Section 3.3: the optimal parameter is `b / (a + b)` when the denominator is nonzero. -/
theorem quadratic_covariance_minimizer (a b : ℝ) (hab : a + b ≠ 0) :
    (b / (a + b)) ^ 2 * a + (1 - b / (a + b)) ^ 2 * b = a * b / (a + b) := by
  rw [quadratic_covariance_identity a b _ hab]
  ring

/-- Section 3.3: optimize the bound for every parameter, including the zero-denominator case.

In the application, `a` and `b` are the two covariances and `c` is twice the sum over
pairs of Fourier indices with odd intersection in Theorem 1.4. -/
theorem le_harmonic_half_of_quadratic_bound {a b c : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b)
    (h : ∀ t : ℝ, c ≤ t ^ 2 * a + (1 - t) ^ 2 * b) :
    c ≤ a * b / (a + b) := by
  by_cases hab : a + b = 0
  · have ha0 : a = 0 := by linarith
    have hb0 : b = 0 := by linarith
    simpa [ha0, hb0] using h 0
  · simpa [quadratic_covariance_minimizer a b hab] using h (b / (a + b))

/-- The algebraic last step of Theorem 1.2: combine (16) with the optimized Theorem 1.4. -/
theorem le_harmonic_of_spectral_bound {a b c w : ℝ} (ha : 0 ≤ a) (hb : 0 ≤ b)
    (hw : w ≤ 2 * c) (h : ∀ t : ℝ, c ≤ t ^ 2 * a + (1 - t) ^ 2 * b) :
    w ≤ 2 * a * b / (a + b) := by
  have hc := le_harmonic_half_of_quadratic_bound ha hb h
  calc
    w ≤ 2 * c := hw
    _ ≤ 2 * (a * b / (a + b)) := mul_le_mul_of_nonneg_left hc (by norm_num)
    _ = 2 * a * b / (a + b) := by ring

/-- Corollary 1.3: the harmonic mean of two equal nonnegative covariances is that covariance. -/
theorem harmonic_self (a : ℝ) : 2 * a * a / (a + a) = a := by
  by_cases ha : a = 0
  · simp [ha]
  · field_simp
    ring

end Chvatal
