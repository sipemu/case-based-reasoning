# Interpreting Results

## `get_similar_cases()`

| Column | Meaning |
|--------|---------|
| training columns | the retrieved case |
| `scDist` | the distance to the query. Comparable only within one model and distance method |
| `caseId` | the rank of the match for its query (1 = most similar) |
| `scCaseId` | the query number shared by a query and its matches (only with `merge = TRUE`) |
| `group` | `"Query"` / `"Matched"` (only with `merge = TRUE`) |

Distance scales by model:

| Model | Scale of the distance |
|-------|-----------------------|
| regression | outcome scale: a Cox `d` of 0.1 means the hazard ratio is at most 1.105 |
| Gower | in [0, 1] (share of the features' ranges) |
| forest depth | mean number of edges between the leaves |
| forest proximity | `sqrt(1 - p)` in [0, 1] |
| RF-GAP | close to 1; only the order is meaningful |

## `explain_match(query, case)`

- **Regression:** one row per model term.
  - `query_contribution` and `case_contribution` are the term's contributions to the
    linear predictor.
  - `distance` is their absolute difference, and `share` is its part of the total.
  - A spline such as `rcs(age, 3)` is a single term.
  - A large share means "the cases differ mainly here".
  - Terms with share 0 match exactly in their contribution.
- **Gower:** one row per variable, with `weight`. `distance` is the variable's part of
  the Gower distance, and the `distance` values sum to it.
- **Forest:** for the trees where the two cases end in different leaves, `n_trees` counts
  the split variable where their paths diverge. Attribute `same_leaf` is the share of
  trees in which they share a leaf (the proximity).

The nearest case usually matches exactly in the discrete features, so its explanation
names the continuous ones. That shows what *remains* different, not what the distance
weights most.

To see what a distance weights in general, change one feature from its lower to its
upper quartile and measure the distance between the two versions of a case. The
*Comparing the Approaches* vignette (`feature_weights()`) shows how.

## `evaluate()` (class and numeric endpoints)

| Element | Meaning | Better |
|---------|---------|--------|
| `accuracy` | share of correct majority votes | higher |
| `brier` | mean of sum over classes of (p − 1[y = class])²; 0 is perfect, 0.5 is an uninformative binary 50/50 | lower |
| `log_loss` | −mean log probability of the true class (probabilities floored at 1e-15) | lower |
| `rmse`, `mae` | errors of the (weighted) mean, in units of the outcome | lower |
| `n` | number of test cases scored | |

## `evaluate_survival()`

| Element | Meaning | Better |
|---------|---------|--------|
| `c_index` | Uno's concordance of the risk 1 − S(tau) with the observed times. 0.5 is random; 0.6–0.7 is typical for clinical data | higher |
| `ibs` | integrated IPCW Brier score over `times` (default: 20 points between the 10% and 90% quantiles of the training event times). 0.25 is an uninformative 50% prediction | lower |
| `brier` | data.frame of the Brier score at each time | lower |

With fewer than about 100 test cases, C-index differences below about 0.03 are within
noise. Use repeated splits or cross-validation.

## `assess_cases(k, horizon, tolerance)`

Each case is judged against its `k` nearest *other* cases.

| Column | Meaning |
|--------|---------|
| `outcome` | class, value, or event status at `horizon` (NA: censored before `horizon`, so not assessed) |
| `agreement` | share of the `k` neighbours with the same outcome |
| `noisy` | `TRUE` if the majority (numeric: the mean, within `tolerance`) of the neighbours disagrees (Wilson editing) |
| `n_reachable` | number of cases that solve this case (a neighbour with the same outcome) |
| `n_coverage` | number of cases this case solves |
| `category` | `pivotal`: no other case solves it, so removing it loses competence. `auxiliary`: another case that solves it covers everything it covers, so it is redundant. `other`: everything else (Smyth & Keane, 1995) |

Typical actions:

- Remove the noisy cases: `remove_cases(rownames(a)[which(a$noisy)])`.
- Inspect the pivotal cases, which are unusual but unique.
- Remove auxiliary cases only to shrink a large case base.
- After removing cases, re-evaluate on held-out data.

## Common Pitfalls

| Symptom | Cause and fix |
|---------|---------------|
| `Missing values in query (rows: ...)` | queries must be complete: impute them or drop those rows |
| `Unknown level(s) of '<var>' in query` | the query has a level that is not in the training data: recode it, or add such cases to the training data |
| `'k' (..) is larger than the number of available training cases` | lower `k` (and remember that `exclude_self = TRUE` removes one) |
| `NA values in regression beta coefficients!` | a term is not estimable (collinear or constant): drop or merge it |
| `Proximity type 'rfgap' needs the in-bag counts of all cases ...` after `add_cases()` | in-bag counts are stale: call `$fit()` |
| RF results change between runs | set `set.seed()` before `$fit()`, or pass `seed =` to `RFModel$new()` |
| All RF-GAP distances are ~1 | expected: only their order matters |
| `The status variable '<var>' must be 0/1 or logical.` | recode the status (e.g. `status - 1` for `survival::lung`) |
| A query returns itself as the nearest case | it is in the training data: use `exclude_self = TRUE` |
