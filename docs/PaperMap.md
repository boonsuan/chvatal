# Paper-to-code map

Reference: Chang–Liu–Liu, [arXiv:2609.19123v1](https://arxiv.org/html/2609.19123v1),
submitted 16 September 2026. All declarations below belong to `Chvatal`;
`Family.` denotes its nested namespace. The version is fixed so future paper
revisions do not silently change the target.

## Numbered results

| Paper | Declaration(s) | File |
|---|---|---|
| Theorem 1.1 | `chvatal`, `exists_largest_intersecting_star` | [Main](../Chvatal/Main.lean) |
| Theorem 1.2 | `sharp_correlation` | [Main](../Chvatal/Main.lean) |
| Corollary 1.3 | `antipodal_correlation`, `antipodal_correlation_bound` | [Main](../Chvatal/Main.lean) |
| Theorem 1.4 | `two_spectral_le_quadratic_covariance` | [Correlation](../Chvatal/Correlation.lean) |
| Theorem 2.1 | `bessel_inequality` | [Bessel](../Chvatal/Bessel.lean) |
| Lemma 3.1(i) | `monomial_eq_zero_of_not_mem`, `fourier_monomial_eq_zero_of_mem` | [Auxiliary](../Chvatal/Auxiliary.lean) |
| Lemma 3.1(ii) | `twistedMonomial_eq_zero_of_not_mem`, `fourier_twistedMonomial_eq_zero_of_not_mem` | [Auxiliary](../Chvatal/Auxiliary.lean) |
| Lemma 3.1(iii) | `linearIndependent_monomial_subfamily`, `linearIndependent_twistedMonomial` | [Auxiliary](../Chvatal/Auxiliary.lean) |
| Lemma 3.1(iv) | `monomial_twistedMonomial_orthogonal` | [Auxiliary](../Chvatal/Auxiliary.lean) |
| Corollary 3.2 | `auxiliary_orthonormal_system` | [Auxiliary](../Chvatal/Auxiliary.lean) |
| Lemma 3.3 | `influence_le_flip_energy`, `maxInfluence_le_odd_spectral` | [Boolean](../Chvatal/Boolean.lean), [Spectral](../Chvatal/Spectral.lean) |
| Proposition 4.1 | `Family.isMaximalIntersecting_iff`, `Family.IsMaximalIntersecting.card_eq` | [Family](../Chvatal/Family.lean) |
| Section 4 equivalence | `chvatal_iff_antipodal_correlation` | [Counting](../Chvatal/Counting.lean) |
| Proposition 5.1 | `andFunction_sharp`, `andFunction_antipodal_sharp`, `quarter_coefficient_optimal` | [Sharpness](../Chvatal/Sharpness.lean) |
| Remark 5.2 | `and_or_two_example` | [Sharpness](../Chvatal/Sharpness.lean) |
| Proposition 5.3 | `kleitman_weighted_bound` | [Weighted](../Chvatal/Weighted.lean) |
| Proposition 5.3, maximum attainment | `exists_largest_weighted_intersecting_star` | [Weighted](../Chvatal/Weighted.lean) |

## Numbered equations

An equation used as an inequality retains that inequality in its formal statement.
Where an equation is an intermediate rewrite, the table identifies its more
general reusable lemma.

| Equation | Declaration(s) |
|---|---|
| (1) | `sharp_correlation` |
| (2) | `antipodal_correlation` |
| (3) | `two_spectral_le_quadratic_covariance` |
| (4) | `spectralWeight_le_four_spectral` |
| (5) | `boundary_sub_const`, `boundary_eq_total_sub_interior` |
| (6) | `influence_eq_signed_mean` |
| (7) | `auxiliaryKernel_norm_sq`, `auxiliaryKernel_energy_identity` |
| (8) | `auxiliaryKernel_inner_outside`, `auxiliaryKernel_inner_inside` |
| (9) | `monomial_expansion`, `fourier_monomial` |
| (10) | `flip_energy_fourier`, `flip_energy_odd` |
| (11) | `weighted_flip_energy`, `two_spectral_eq_boundary` |
| (12) | `boundary_sub_const` |
| (13) | `boundary_eq_total_sub_interior` |
| (14) | `auxiliaryKernel_bessel_bound` |
| (15) | `maxInfluence_le_flip_energy`, `flip_energy_odd`, `maxInfluence_le_odd_spectral` |
| (16) | `spectralWeight_le_four_spectral` |
| (17) | `Family.covariance_sub_quarter_min_influence` |
| (18) | `kleitman_weighted_bound` |

## Supporting mathematics

- Section 2's Fourier conventions are `cubeMean`, `walsh`, and `fourier`.
  Character orthogonality, inversion, Parseval, duality, and covariance expansions
  are proved in [Fourier](../Chvatal/Fourier.lean).
- Probability normalization is connected to mathlib's `EuclideanSpace` by
  `uniformEuclidean` and `inner_uniformEuclidean`. Bessel and Gram–Schmidt use
  existing inner-product-space theorems through this proved normalization.
- The monomial and twisted-monomial support **equalities**, not only the
  inclusions required for Lemma 3.1, are `support_monomial`,
  `support_fourier_monomial`, `support_twistedMonomial`, and
  `support_fourier_twistedMonomial`.
- `supportSubspace` collects both physical and Fourier support conditions.
  Corollary 3.2's orthonormal families are indexed by the actual difference
  families, so their cardinalities are exact, including when either family is empty.
- [Optimization](../Chvatal/Optimization.lean) proves the quadratic minimization
  and separately handles the zero-denominator case in Theorem 1.2.
- Section 4's covariance and influence counts are
  `Family.covariance_one_sub_indicator` and `Family.influence_one_sub_indicator`.
  Both directions of the correlation/star equivalence are proved; `Main`
  discharges the analytic assertion rather than assuming it.
- [LayerCake](../Chvatal/LayerCake.lean) proves the finite level-set decomposition
  underlying the last part of Proposition 5.3. It allows arbitrary nonnegative
  antitone real weights, with no rationality or integrality restriction.
- [Signed](../Chvatal/Signed.lean) formalizes the closing paragraph's conversion
  between Boolean and signed Boolean functions, antipodality, the positive part,
  and the corresponding Fourier and spectral coefficient formulas.

## Faithfulness and boundary cases

The coordinate type is any finite type, rather than only `Fin n`. The cube has
`Fintype.card (Finset ι) = 2 ^ Fintype.card ι` points. The normalizing factor in
all averages is exactly this cardinality.

Theorems requiring a star center or a minimum influence explicitly require a
nonempty coordinate type. Proposition 4.1 needs the same restriction: on an empty
ground type the empty family is maximal intersecting but cannot be antipodal.
This is the paper's implicit `n ≥ 1` convention made explicit. The harmonic and
quadratic correlation theorems remain valid on the zero-dimensional cube.

`IsIntersecting` uses pairwise non-disjointness including a member with itself;
it does not silently allow the empty set. `IsBoolean` restricts values to zero
and one and imposes no extra analytic property. Every monotonicity hypothesis
is the usual subset-order monotonicity. The coordinate influences are proved
equal to the paper's probability of changing under a flip.

GPT-6 agents checked the normalization, definitions, and final statements in
addition to compiling the proofs. This was an AI-assisted source-correspondence
review, not independent human mathematical review. [The executable audit](../scripts/Audit.lean) also restates
Theorem 1.1 without any of this project's family predicates and checks all
exported theorem dependencies against the three standard Lean axioms.
