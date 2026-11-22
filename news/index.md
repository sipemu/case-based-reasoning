# Changelog

## CaseBasedReasoning (development version)

### New features

- `predict_outcome()` predicts class and numeric outcomes from the `k`
  most similar training cases: a (tricube-weighted) majority vote with
  class probabilities, or a (weighted) mean. `evaluate()` scores the
  predictions on test data (accuracy, Brier score and log loss; RMSE and
  MAE) and delegates to `evaluate_survival()` for survival endpoints.
  [`predict()`](https://rdrr.io/r/stats/predict.html) gains
  `type = c("cases", "outcome", "survival")`; the default still returns
  the similar cases
  ([\#43](https://github.com/sipemu/case-based-reasoning/issues/43)).
- `GowerModel` and
  [`gower_distance()`](https://sipemu.github.io/case-based-reasoning/reference/gower_distance.md):
  the model-free Gower (1971) distance for mixed data (numeric, nominal,
  ordinal and logical variables, optional weights) as a baseline for the
  model-derived distances. Ranges come from the training cases, so query
  distances do not depend on the batch. All CBR methods (retrieval,
  outcome and survival prediction, counterfactuals, `explain_match()`)
  work with it
  ([\#44](https://github.com/sipemu/case-based-reasoning/issues/44)).
- Retain: `add_cases()` adds solved cases to the case base without
  refitting the model (or with `refit = TRUE`), `remove_cases()` removes
  cases by row name or position, and `get_case_base()` returns the
  current case base. New cases are validated like queries. OOB and
  RF-GAP proximities of `RFModel` need a refit after the case base was
  changed
  ([\#45](https://github.com/sipemu/case-based-reasoning/issues/45)).
- Case-base maintenance: `assess_cases()` retrieves each case against
  the others (leave-one-out) and reports the agreement with its
  neighbours, noisy cases (Wilson editing, 1972) and the competence
  categories of Smyth & Keane (1995): pivotal cases that no other case
  solves and redundant (auxiliary) cases whose coverage another case
  subsumes. Combine it with `remove_cases()` to edit the case base
  ([\#46](https://github.com/sipemu/case-based-reasoning/issues/46)).

### Documentation

- New article “Benchmark: Model-Derived Distances vs. Learned Metrics”
  on the package website: the regression, random forest and Gower
  distances against a learned metric (diagonal NCA) on four data sets,
  with irrelevant variables and for survival
  ([\#42](https://github.com/sipemu/case-based-reasoning/issues/42)).
  README and the get-started vignette cover outcome prediction, the
  Gower distance, retaining and maintaining cases.

### Bug fixes

- Ordered factors in queries stay ordered. Queries were converted to
  unordered factors when aligned to the training data, which changed the
  design matrix of regression models fitted with ordered factors.

## CaseBasedReasoning 0.5.0

### Bug fixes

- Factor values in queries are now matched to the training data by level
  name instead of internal integer code. Queries with different or
  dropped factor levels previously got silently wrong distances. Unknown
  levels are now an error
  ([\#4](https://github.com/sipemu/case-based-reasoning/issues/4)).
- Character predictors no longer break distance calculation after
  `fit()`
  ([\#5](https://github.com/sipemu/case-based-reasoning/issues/5)).
- Training cases with missing values are excluded consistently from
  fitting, distance calculation and retrieval. A single `NA` used to
  make `get_similar_cases()` fail. Missing values in the query are now
  an informative error
  ([\#6](https://github.com/sipemu/case-based-reasoning/issues/6)).
- `get_similar_cases()` validates `k`: it must be a whole number and at
  most the number of training cases
  ([\#7](https://github.com/sipemu/case-based-reasoning/issues/7)).
- `get_similar_cases(merge = TRUE)` works for queries without endpoint
  columns
  ([\#8](https://github.com/sipemu/case-based-reasoning/issues/8)).
- `variable_selection()` now returns the variables retained by
  [`rms::fastbw()`](https://rdrr.io/pkg/rms/man/fastbw.html) instead of
  all variables. Further arguments are passed on to `fastbw()`, and
  `update = TRUE` restricts the model to the selected variables
  ([\#9](https://github.com/sipemu/case-based-reasoning/issues/9)).
- [`proximity_distance()`](https://sipemu.github.io/case-based-reasoning/reference/proximity_distance.md)
  converts proximity to distance as `sqrt(1 - p)`. It previously used
  `sqrt(max(p) - p)`, so distances depended on the observations in the
  batch. Absolute distance values change; the neighbour order within a
  query does not
  ([\#10](https://github.com/sipemu/case-based-reasoning/issues/10)).
- Depth distance no longer loses the edge counts of earlier trees in
  forests with more than one tree. Depth distances were too small, and
  neighbour rankings could be wrong
  ([\#28](https://github.com/sipemu/case-based-reasoning/issues/28)).
- [`weighted_distance()`](https://sipemu.github.io/case-based-reasoning/reference/weighted_distance.md)
  defaults to equal weights instead of `1, 2, ..., p` and checks the
  length of `weights`
  ([\#14](https://github.com/sipemu/case-based-reasoning/issues/14)).
- `RFModel` no longer forces `verbose = TRUE` for ranger
  ([\#15](https://github.com/sipemu/case-based-reasoning/issues/15)).
- The `threads` argument of
  [`distance_random_forest()`](https://sipemu.github.io/case-based-reasoning/reference/distance_random_forest.md)
  only applies to that call, and the previous RcppParallel setting is
  restored
  ([\#17](https://github.com/sipemu/case-based-reasoning/issues/17)).
- Regression weights for numeric variables are no longer double-named
  ([\#18](https://github.com/sipemu/case-based-reasoning/issues/18)).
- Depth distance no longer precomputes a table over all pairs of
  terminal nodes. Edge counts are computed on demand from each tree’s
  parent and depth arrays: n = 1500 with 100 trees now takes seconds
  instead of not finishing, and memory is linear in the number of nodes
  ([\#12](https://github.com/sipemu/case-based-reasoning/issues/12)).
- `orderMatrix()` honours `sortDirection` in TBB builds and clamps `k`
  to the number of rows
  ([\#25](https://github.com/sipemu/case-based-reasoning/issues/25)).
- Corrected the DOI of Englund & Verikas (2012)
  ([\#19](https://github.com/sipemu/case-based-reasoning/issues/19)).

### New features

- `get_counterfactual_cases()` returns the nearest training cases whose
  outcome differs from the query’s: a different class, a numeric outcome
  differing by at least `min_diff`, or a different event status at
  `horizon` for survival endpoints (Keane & Smyth, 2020). If the query
  has no outcome, it is predicted from its most similar cases
  ([\#23](https://github.com/sipemu/case-based-reasoning/issues/23)).
- `explain_match(query, case)` explains a match. For regression models
  it gives each term’s contribution to the linear predictor and its
  share of the distance; for random forests, the split variables at
  which the two cases’ tree paths diverge
  ([\#22](https://github.com/sipemu/case-based-reasoning/issues/22),
  [\#23](https://github.com/sipemu/case-based-reasoning/issues/23)).
- `predict_survival()` predicts survival curves for survival endpoints
  from the retrieved cases: a Kaplan-Meier estimate over each query’s
  `k` nearest training cases, optionally weighted with a tricube kernel
  (Lowsky et al., 2013). `evaluate_survival()` scores these predictions
  on test data with Uno’s C-index and the IPCW (integrated) Brier score,
  so that `k` and the distance method can be chosen on held-out data
  ([\#21](https://github.com/sipemu/case-based-reasoning/issues/21)).
- Out-of-bag and RF-GAP random forest proximities (Rhodes, Cutler &
  Moon, 2023):
  `proximity_distance(type = c("original", "oob", "rfgap"))`,
  `distance_random_forest(proximity_type = )` and
  `RFModel$set_distance_method("Proximity", proximity_type = )`. RF-GAP
  removes the in-bag bias of the original proximity, and its
  proximity-weighted average of the training outcomes reproduces the
  forest’s (out-of-bag) prediction. `RFModel` now keeps the in-bag
  counts by default
  ([\#20](https://github.com/sipemu/case-based-reasoning/issues/20)).
- Regression models (`CoxModel`, `LinearModel`, `LogisticModel`) support
  any rms term: splines (`rcs()`, `pol()`, …), interactions and so on
  ([\#11](https://github.com/sipemu/case-based-reasoning/issues/11)).
  Distances are computed in *contribution space*: each term’s
  contribution to the linear predictor, `c_t(x) = X_t(x) %*% beta_t`,
  compared with a weighted L1 distance. For main effects this is
  identical to the previous weighted distance (Dippon et al., 2002)
  ([\#22](https://github.com/sipemu/case-based-reasoning/issues/22)).
- New public field `variables` holds the data columns used by the
  formula; `terms` holds the term labels.
- `get_similar_cases(exclude_self = TRUE)` excludes training cases with
  the same row name as the query, so in-sample queries do not return
  themselves
  ([\#13](https://github.com/sipemu/case-based-reasoning/issues/13)).

### Documentation

- README and vignettes cover contribution-space distances, survival
  prediction and evaluation, counterfactual cases, match explanations
  and OOB/RF-GAP proximities. Corrected the description of the `caseId`
  column (the rank of a match) and the proximity and depth formulas
  (distance `sqrt(1 - p)`; depth is summed over trees; categorical
  distance is 1 when levels differ).

### Internal

- Removed dead and duplicate C++ code (`cpp_weighted_knn()`,
  `cpp_orderVector()`, unused containers and headers) and fixed compiler
  warnings
  ([\#24](https://github.com/sipemu/case-based-reasoning/issues/24),
  [\#25](https://github.com/sipemu/case-based-reasoning/issues/25)).
- Added value and regression tests for distances and retrieval
  ([\#26](https://github.com/sipemu/case-based-reasoning/issues/26)).
- Tests use at most 2 threads.
