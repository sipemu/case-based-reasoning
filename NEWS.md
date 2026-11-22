## CaseBasedReasoning (development version)

### Bug fixes

- Factor values in queries are now matched to the training data by level name
  instead of internal integer code. Queries with different or dropped factor
  levels previously got silently wrong distances. Unknown levels are now an
  error (#4).
- Character predictors no longer break distance calculation after `fit()` (#5).
- Training cases with missing values are excluded consistently from fitting,
  distance calculation and retrieval. A single `NA` used to make
  `get_similar_cases()` fail. Missing values in the query are now an
  informative error (#6).
- `get_similar_cases()` validates `k`: it must be a whole number and at most
  the number of training cases (#7).
- `get_similar_cases(merge = TRUE)` works for queries without endpoint columns
  (#8).
- `variable_selection()` now returns the variables retained by `rms::fastbw()`
  instead of all variables. Further arguments are passed on to `fastbw()`, and
  `update = TRUE` restricts the model to the selected variables (#9).
- `proximity_distance()` converts proximity to distance as `sqrt(1 - p)`. It
  previously used `sqrt(max(p) - p)`, so distances depended on the observations
  in the batch. Absolute distance values change; the neighbour order within a
  query does not (#10).
- Depth distance no longer loses the edge counts of earlier trees in forests
  with more than one tree. Depth distances were too small, and neighbour
  rankings could be wrong (#28).
- `weighted_distance()` defaults to equal weights instead of `1, 2, ..., p` and
  checks the length of `weights` (#14).
- `RFModel` no longer forces `verbose = TRUE` for ranger (#15).
- The `threads` argument of `distance_random_forest()` only applies to that
  call, and the previous RcppParallel setting is restored (#17).
- Regression weights for numeric variables are no longer double-named (#18).
- Depth distance no longer precomputes a table over all pairs of terminal
  nodes. Edge counts are computed on demand from each tree's parent and depth
  arrays: n = 1500 with 100 trees now takes seconds instead of not finishing,
  and memory is linear in the number of nodes (#12).
- `orderMatrix()` honours `sortDirection` in TBB builds and clamps `k` to the
  number of rows (#25).
- Corrected the DOI of Englund & Verikas (2012) (#19).

### New features

- Out-of-bag and RF-GAP random forest proximities (Rhodes, Cutler & Moon,
  2023): `proximity_distance(type = c("original", "oob", "rfgap"))`,
  `distance_random_forest(proximity_type = )` and
  `RFModel$set_distance_method("Proximity", proximity_type = )`. RF-GAP
  removes the in-bag bias of the original proximity, and its
  proximity-weighted average of the training outcomes reproduces the forest's
  (out-of-bag) prediction. `RFModel` now keeps the in-bag counts by default
  (#20).
- Regression models (`CoxModel`, `LinearModel`, `LogisticModel`) support any
  rms term: splines (`rcs()`, `pol()`, ...), interactions and so on (#11).
  Distances are computed in *contribution space*: each term's contribution to
  the linear predictor, `c_t(x) = X_t(x) %*% beta_t`, compared with a
  weighted L1 distance. For main effects this is identical to the previous
  weighted distance (Dippon et al., 2002) (#22).
- New public field `variables` holds the data columns used by the formula;
  `terms` holds the term labels.
- `get_similar_cases(exclude_self = TRUE)` excludes training cases with the same
  row name as the query, so in-sample queries do not return themselves (#13).

### Internal

- Removed dead and duplicate C++ code (`cpp_weighted_knn()`,
  `cpp_orderVector()`, unused containers and headers) and fixed compiler
  warnings (#24, #25).
- Added value and regression tests for distances and retrieval (#26).
- Tests use at most 2 threads.

## 0.4.2

### Bug fixes

- Removed blanket `import(rms)` and `import(survival)` from NAMESPACE. Newer
  versions of rms export `cluster()`, which clashed with `survival::cluster()`
  and caused an install-time warning on CRAN. All rms/survival functions are
  already called with explicit namespaces.

## 0.4.1

### Breaking changes

- Redesigned API: snake_case function names (`distance_random_forest`,
  `weighted_distance`, `terminal_nodes`, `as_dist_object`). Old camelCase
  names still work but emit deprecation warnings.
- R6 field names changed to snake_case (`endpoint`, `dist_matrix`,
  `order_matrix`). Old names emit deprecation warnings.
- S3 generics added: `predict()`, `print()`, `summary()` for all model classes.

### Bug fixes

- Fix off-by-one error in terminal node IDs for RF depth distance.
- Fix compilation on musl/Alpine Linux (no TBB fallback).
- Fix platform-dependent test failure in ordering tests.
- Replace broken URLs with stable DOI links.

### Improvements

- Improved vignettes: added `set.seed()` for reproducibility, tightened prose.
- Removed archived `pryr` dependency; replaced with base `do.call`.
- Removed `data.table` dependency.
- Added CI/CD via GitHub Actions (macOS, Windows, Ubuntu).


## 0.3

### Features

- Add more unit tests
- Add R6 documentation
- Generalize the RandomForest model to classification and regression
- Update vignettes

### Bugfixes

- Fix ranger package to version 0.11.2
- Terminal nodes were wrongly calculated
- Fix Armadillo deprecation warnings


## 0.22

### Bugfixes

- Weighted distance calculation was wrongly calculated, namely: $abs(sum(x-y))$ to $sum(abs(x-y))$. This has an effect on all linear models.