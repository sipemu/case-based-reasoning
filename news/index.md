# Changelog

## CaseBasedReasoning (development version)

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
- `orderMatrix()` honours `sortDirection` in TBB builds and clamps `k`
  to the number of rows
  ([\#25](https://github.com/sipemu/case-based-reasoning/issues/25)).
- Corrected the DOI of Englund & Verikas (2012)
  ([\#19](https://github.com/sipemu/case-based-reasoning/issues/19)).

### New features

- `get_similar_cases(exclude_self = TRUE)` excludes training cases with
  the same row name as the query, so in-sample queries do not return
  themselves
  ([\#13](https://github.com/sipemu/case-based-reasoning/issues/13)).

### Internal

- Removed dead and duplicate C++ code (`cpp_weighted_knn()`,
  `cpp_orderVector()`, unused containers and headers) and fixed compiler
  warnings
  ([\#24](https://github.com/sipemu/case-based-reasoning/issues/24),
  [\#25](https://github.com/sipemu/case-based-reasoning/issues/25)).
- Added value and regression tests for distances and retrieval
  ([\#26](https://github.com/sipemu/case-based-reasoning/issues/26)).
- Tests use at most 2 threads.
