# A formalization of Chang, Liu, and Liu's proof of Chvátal's conjecture

A **Lean 4 + mathlib formalization** of Fan Chang, Hong Liu, and Miao Liu's
paper, [*A proof of Chvátal's conjecture via a sharp correlation inequality*,
arXiv:2609.19123v1](https://arxiv.org/abs/2609.19123v1).

**The mathematical contribution and proof are due to Chang, Liu, and Liu.**
I used **GPT-6 through Codex** to formalize their paper and prepare this
repository. I made **no mathematical contribution**. The purpose
is to provide a reproducible Lean formalization that gives readers additional
confidence in the paper's correctness.

The Lean development and accompanying documentation were generated with GPT-6,
including parallel agents. Kernel checking verifies the formal proofs; it does
not by itself establish that the formal statements faithfully express the paper.
No independent human mathematical review was done. The source references,
readable statements, and explicit conventions below are intended to make that
comparison possible.

## Where to start

- **Read the result:** [the main theorem](#the-main-theorem) below states the
  conjecture in set-family language and shows how to use its Lean proof.
- **Follow the mathematics:** the [proof roadmap](#proof-roadmap) explains the
  correlation argument; the [paper-to-code map](docs/PaperMap.md) locates every
  numbered result and equation.
- **Inspect the formal claims:** [Challenge.lean](Challenge.lean) contains the
  statements prepared for Palomar, separately from their proofs in
  [Solution.lean](Solution.lean).
- **Reproduce the checks:** follow [build and verify](#build-and-verify).
  [Chvatal.lean](Chvatal.lean) imports the full mathematical library.

## The main theorem

A family $D$ of subsets of a finite nonempty ground set is **hereditary** if every subset
of a member also belongs to $D$. A family $A$ is **intersecting** if every two
of its members have nonempty intersection. For a coordinate $i$, the **star**
$D_i$ consists of the members of $D$ containing $i$.

**Theorem 1.1.** If $A \subseteq D$, $D$ is hereditary, and $A$ is intersecting,
then there is a coordinate $i$ such that $|A| \leq |D_i|$.

The proof is `Chvatal.chvatal` in [Chvatal/Main.lean](Chvatal/Main.lean).
This complete Lean example uses it:

```lean
import Chvatal.Main

open Chvatal

example {ι : Type*} [Finite ι] [DecidableEq ι] [Nonempty ι]
    {D A : Family ι} (hD : D.IsHereditary)
    (hAD : A ⊆ D) (hA : A.IsIntersecting) :
    ∃ i : ι, A.card ≤ (D.star i).card :=
  Chvatal.chvatal hD hAD hA
```

Here `Family ι` means `Finset (Finset ι)`: a finite family of finite subsets.
`Finite ι` says the ground type is finite, `DecidableEq ι` supplies equality
testing, and `Nonempty ι` allows a star center to be chosen. Taking `ι = Fin n`
recovers the paper's ground set, with a harmless change of labels to
$0,\ldots,n-1$.

The declaration `exists_largest_intersecting_star` proves the simultaneous
formulation: **one star of $D$ is at least as large as every intersecting
subfamily of $D$**, and that star is itself intersecting. It is obtained by
choosing a largest star and applying Theorem 1.1 to each competing subfamily.

## Proof roadmap

The formalization follows the paper's route through Fourier analysis on the
Boolean cube. For increasing Boolean functions $f,g$, let
$g^*(x)=1-g(x^c)$, let $I_i(f)$ be the probability that flipping coordinate
$i$ changes $f$, and write $\widehat g(S)$ for the uniformly normalized
Fourier–Walsh coefficient. Theorem 1.2 is

```math
\sum_{\varnothing\ne S}\widehat g(S)^2\max_{i\in S} I_i(f)
\;\leq\;
\frac{2\,\mathrm{Cov}(f,g)\,\mathrm{Cov}(f,g^{*})}
{\mathrm{Cov}(f,g)+\mathrm{Cov}(f,g^{*})},
```

with value zero when the denominator vanishes. Its Lean declaration is
`sharp_correlation`.

1. **Build the auxiliary orthonormal system.** Monomials and twisted monomials
   have the physical and Fourier support properties of Lemma 3.1.
   Gram–Schmidt preserves these restrictions, giving Corollary 3.2 in
   [Auxiliary](Chvatal/Auxiliary.lean).
2. **Apply Bessel's inequality to the kernel.**
   [Bessel](Chvatal/Bessel.lean) supplies the uniformly normalized inner-product
   framework. [Kernel](Chvatal/Kernel.lean) uses the auxiliary system to bound
   the interior energy; [Correlation](Chvatal/Correlation.lean) subtracts it
   from the total energy to prove the quadratic covariance bound, Theorem 1.4.
3. **Optimize and compare influences.**
   [Boolean](Chvatal/Boolean.lean) and [Spectral](Chvatal/Spectral.lean) prove
   Lemma 3.3's influence comparison. [Optimization](Chvatal/Optimization.lean)
   minimizes the quadratic, and [Main](Chvatal/Main.lean) combines the bounds
   to obtain Theorem 1.2.
4. **Return to set families.** For antipodal $g=g^*$, Parseval yields
   $\frac14\min_i I_i(f)\leq\mathrm{Cov}(f,g)$, Corollary 1.3.
   [Counting](Chvatal/Counting.lean) translates this into the star bound using
   $f=1-\mathbf 1_D$ and $g=\mathbf 1_B$, where $B$ is a maximal intersecting
   extension of $A$. [Family](Chvatal/Family.lean) proves the required
   maximality and antipodality correspondence.
5. **Cover the final section.** [Sharpness](Chvatal/Sharpness.lean) proves the
   equality examples and optimal constant. [Weighted](Chvatal/Weighted.lean)
   proves Proposition 5.3 using the finite level-set decomposition in
   [LayerCake](Chvatal/LayerCake.lean). [Signed](Chvatal/Signed.lean) formalizes
   the closing conversion to signed Boolean functions.

## Paper-to-code correspondence

The target is **version 1** of the paper. All declaration names below are in
the namespace `Chvatal`; `Family` is a nested namespace. Module introductions,
declaration docstrings, and proof comments explain their roles in the paper.

| Paper result | Principal declaration | Source |
| --- | --- | --- |
| Theorem 1.1: Chvátal's conjecture | `chvatal`, `exists_largest_intersecting_star` | [Main](Chvatal/Main.lean) |
| Theorem 1.2: sharp correlation inequality | `sharp_correlation` | [Main](Chvatal/Main.lean) |
| Corollary 1.3: antipodal correlation bound | `antipodal_correlation` | [Main](Chvatal/Main.lean) |
| Theorem 1.4: quadratic covariance bound | `two_spectral_le_quadratic_covariance` | [Correlation](Chvatal/Correlation.lean) |
| Theorem 2.1: Bessel's inequality | `bessel_inequality` | [Bessel](Chvatal/Bessel.lean) |
| Lemma 3.1 and Corollary 3.2: auxiliary system | support and independence lemmas; `auxiliary_orthonormal_system` | [Auxiliary](Chvatal/Auxiliary.lean) |
| Lemma 3.3: influence comparison | `influence_le_flip_energy`, `maxInfluence_le_odd_spectral` | [Boolean](Chvatal/Boolean.lean), [Spectral](Chvatal/Spectral.lean) |
| Proposition 4.1: maximal intersecting families | `Family.isMaximalIntersecting_iff`, `Family.IsMaximalIntersecting.card_eq` | [Family](Chvatal/Family.lean) |
| Section 4: equivalence of the two formulations | `chvatal_iff_antipodal_correlation` | [Counting](Chvatal/Counting.lean) |
| Proposition 5.1 and Remark 5.2: sharpness | `andFunction_sharp`, `quarter_coefficient_optimal`, `and_or_two_example` | [Sharpness](Chvatal/Sharpness.lean) |
| Proposition 5.3: weighted strengthening | `kleitman_weighted_bound`, `exists_largest_weighted_intersecting_star` | [Weighted](Chvatal/Weighted.lean) |

The [full map](docs/PaperMap.md) also locates each numbered equation, all four
parts of Lemma 3.1, supporting identities, and boundary cases. Historical
discussion and results merely cited from other papers are outside the claimed
formalization scope.

## Mathematical conventions

- **Cube and normalization.** A point is the finite set of its coordinates
  equal to one. `cubeMean` divides by the number of cube points,
  $2^{|\iota|}$; `walsh S x` is $(-1)^{|S\cap x|}$. Fourier inversion,
  Parseval, and the normalization used for Bessel's inequality are proved.
- **Heredity and intersection.** The family predicates use mathlib's
  `IsLowerSet`, `IsUpperSet`, and `Set.Intersecting`. Intersection includes a
  member paired with itself, so an intersecting family cannot contain the
  empty set.
- **Boolean functions.** Functions take values in `ℝ`; `IsBoolean f` requires
  every value to be zero or one. Monotonicity is ordinary subset-order
  monotonicity. Influence is defined as mean squared flip difference and
  proved equal to the probability of changing under a flip.
- **Empty indices and zero denominators.** `maxInfluence f ∅ = 0`, so the empty
  Fourier index contributes nothing. Real division by zero is zero, matching
  the convention in Theorem 1.2; the proof handles this case separately.
- **Dimension zero.** Results choosing a coordinate, taking a minimum
  influence, or characterizing maximal intersecting families as antipodal
  require a nonempty ground type. This makes the paper's positive-dimension
  convention explicit. Theorems 1.2 and 1.4 also hold in dimension zero.
- **Weights.** Proposition 5.3 allows arbitrary nonnegative decreasing real
  weights. A finite level-set sum replaces the layer-cake integral. The
  spectral coefficients are first handled for a general coordinate selector,
  then specialized to the maximum in a fixed total order, as in the paper.

## Build and verify

The project pins **Lean 4.33.1** and **mathlib v4.33.1**, at mathlib commit
`0df444a360eaa60ab8c11dca51a86af692955474`. The committed
[lake-manifest.json](lake-manifest.json) pins transitive dependencies.

With [elan](https://github.com/leanprover/elan) installed, run these commands
from this repository's root:

```sh
lake exe cache get
./scripts/verify.sh
```

`lake exe cache get` downloads precompiled mathlib dependencies when needed;
elan selects the toolchain from [lean-toolchain](lean-toolchain). If `lake`
is missing from the terminal's PATH, run `source "$HOME/.elan/env"` first.
The repository builds from its pinned dependencies; a sibling checkout or
an existing local dependency cache is not required.

[scripts/verify.sh](scripts/verify.sh) builds the library and solution with
warnings treated as errors, runs the statement and axiom audit, and runs the
configured mathlib linters. [scripts/Audit.lean](scripts/Audit.lean) checks a
direct finite-set restatement of the main theorem and audits transitive
dependencies of the exported proofs. The permitted axioms are Lean's standard:

```text
propext, Classical.choice, Quot.sound
```

The mathematical library and solution contain no proof placeholders, added
mathematical axioms, or native-evaluation axioms. The `sorry` declarations in
the separate [Challenge.lean](Challenge.lean) are intentional statement-only
placeholders for Comparator; that file is not imported by the proofs.

## Verification and Palomar

The local submission materials separate the claims from their implementation:
[Challenge.lean](Challenge.lean) states the principal results,
[Solution.lean](Solution.lean) proves those statements using the library, and
[comparator.json](comparator.json) configures their comparison.
[docs/PALOMAR.md](docs/PALOMAR.md) gives the preparation and verification steps;
[docs/Verification.md](docs/Verification.md) records the checks performed.

Compilation and axiom auditing establish facts about the formal declarations.
The relationship between those declarations and the informal paper remains a
matter for mathematical reading. The documentation and AI-assisted checks do
not amount to independent human peer review.

[Palomar's verification model](https://palomar-registry.org/about) adds
separate statement/proof comparison and kernel checks for a pinned repository
snapshot. Its scope and limitations are also explained in
[Terence Tao's announcement](https://terrytao.wordpress.com/2026/08/18/palomar-a-registry-of-lean-verified-mathematics/).

## Credits and license

- **Mathematics and original proof:** Fan Chang, Hong Liu, and Miao Liu,
  [arXiv:2609.19123v1](https://arxiv.org/abs/2609.19123v1).
- **Formalization and documentation generation:** GPT-6, used through Codex.
- **My role:** prompting GPT-6 and maintaining this repository. I made no
  mathematical contribution.
- **Proof assistant and mathematical infrastructure:** Lean and mathlib,
  and their contributors.

The repository's code and documentation are released under the
[MIT License](LICENSE). Lean, mathlib, and other dependencies retain their own
licenses. The paper retains its own arXiv license; its text is not included in
the distributable source tree.
