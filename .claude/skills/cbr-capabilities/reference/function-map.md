# Function and Method Map

These are the methods and functions exported by CaseBasedReasoning 0.5.x. Don't invent
names or arguments that are not listed here. Re-check the signatures with
`args(asNamespace("CaseBasedReasoning")$CBRBase$public_methods$<name>)`.

## Shared R6 methods (all model classes, defined in `CBRBase`)

### Life cycle

| Method | Returns | Notes |
|--------|---------|-------|
| `$new(formula, data)` | model object | `RFModel$new(formula, data, ...)`, `GowerModel$new(formula, data, weights = NULL)`, `BoostModel$new(formula, data, nrounds = 100, params = list(eta = 0.1, max_depth = 3))` |
| `$fit()` | the object, invisibly | drops incomplete training cases (warning); must be called before any other method |
| `$print()`, `summary(model)` | — | |

### Retrieve

| Method | Returns |
|--------|---------|
| `$calc_distance_matrix(query = NULL)` | n x n (training) or n x m (training x query) distance matrix; also stored in `$dist_matrix` |
| `$get_similar_cases(query, k = 1, add_distance = TRUE, merge = FALSE, exclude_self = FALSE)` | data.frame with `k` training cases per query, in query order |
| `$explain_match(query, case)` | data.frame: a decomposition of the distance between two single-row cases (see below) |

`get_similar_cases()` adds these columns to the training columns:

- `scDist`: the distance.
- `caseId`: the rank of the match (1 = most similar).

With `merge = TRUE` the query rows are included, plus two more columns:

- `scCaseId`: the query number.
- `group`: `"Query"` / `"Matched"`. `exclude_self = TRUE` drops a query's own training row (leave-one-out).

`explain_match()` returns one of three shapes, depending on the model:

| Model | Columns | Notes |
|-------|---------|-------|
| regression and `BoostModel` | `term`, `query_contribution`, `case_contribution`, `distance`, `share` | for `BoostModel`, the contributions are SHAP values |
| Gower | `variable`, `query_value`, `case_value`, `weight`, `distance`, `share` | |
| forest | `variable`, `n_trees`, `share` | attribute `same_leaf` |

### Reuse

| Method | Returns |
|--------|---------|
| `$predict_outcome(query, k = 10, weighted = FALSE, exclude_self = FALSE)` | data.frame `prediction`: a factor plus `prob_<level>` columns for classes, or a numeric mean |
| `$predict_survival(query, k = 10, times = NULL, weighted = FALSE)` | matrix of Kaplan–Meier survival probabilities (queries x times, attribute `times`); survival endpoints only |
| `$get_counterfactual_cases(query, k = 1, horizon = NULL, min_diff = NULL, k_outcome = 10)` | the nearest cases with a *different* outcome; adds a `queryOutcome` column |
| `predict(model, newdata, k = NULL, type = c("cases", "outcome", "survival"), ...)` | S3 wrapper: `k` defaults to 1 for `"cases"` and to 10 otherwise |

- `weighted = TRUE` applies tricube kernel weights to the `k` neighbours.
- For survival endpoints, `predict_outcome()` errors; use `predict_survival()`.
- Counterfactual outcomes compare classes, or numbers that differ by at least
  `min_diff` (default: the SD of the outcome).
- For survival endpoints, counterfactuals compare the event status at `horizon`
  (default: the median event time).

### Revise

| Method | Returns |
|--------|---------|
| `$evaluate(test, k = 10, weighted = FALSE, ...)` | classes: list(`accuracy`, `brier`, `log_loss`, `n`); numeric: list(`rmse`, `mae`, `n`); survival: delegates to `evaluate_survival()` |
| `$evaluate_survival(test, k = 10, times = NULL, tau = NULL, weighted = FALSE)` | list(`c_index` (Uno's C), `ibs` (integrated IPCW Brier score), `brier` (data.frame time/brier)) |
| `$check_ph()` | `CoxModel` only: proportional hazards check |

### Retain

| Method | Returns |
|--------|---------|
| `$add_cases(newdata, refit = FALSE)` | the object, invisibly; new cases need a complete endpoint |
| `$remove_cases(cases, refit = FALSE)` | the object, invisibly; `cases` are row names or positions in `get_case_base()` |
| `$get_case_base()` | data.frame of the current cases |
| `$assess_cases(k = 5, horizon = NULL, tolerance = NULL)` | data.frame per case: `outcome`, `agreement`, `noisy`, `n_reachable`, `n_coverage`, `category` (`pivotal` / `auxiliary` / `other`) |

### Public fields

| Field | Content |
|-------|---------|
| `$data` | the training data |
| `$formula` | the model formula |
| `$terms` | the model terms |
| `$variables` | the covariates |
| `$endpoint` | the endpoint columns |
| `$model_fit` | the fitted model |
| `$dist_matrix` | the last distance matrix |
| `$weights` | regression coefficients per term (regression models) or variable weights (Gower) |
| `$dist_method`, `$proximity_type` | `RFModel` only |

## Model-specific methods

| Method | Class |
|--------|-------|
| `$variable_selection(update = FALSE, ...)` | `LinearModel`, `LogisticModel`, `CoxModel` |
| `$check_ph()` | `CoxModel` |
| `$set_distance_method(method = "Depth", proximity_type = "original")` | `RFModel` |
| `$shap_values(data)` | `BoostModel` |

## Standalone functions

| Function | Purpose |
|----------|---------|
| `gower_distance(x, y = NULL, weights = NULL, ranges = NULL)` | Gower distance: a `dist` object within `x`, or an n x m matrix |
| `weighted_distance(x, y = NULL, weights = NULL)` | weighted absolute (L1) distance of numeric matrices |
| `distance_random_forest(x, y = NULL, rfObject, method = "Proximity", threads = NULL, proximity_type = c("original", "oob", "rfgap"))` | forest distance for any `ranger` object (`write.forest = TRUE`; OOB and RF-GAP also need `keep.inbag = TRUE`) |
| `proximity_distance(x, y = NULL, rfObject, as_dist = TRUE, type = c("original", "oob", "rfgap"))` | proximity-based distance `sqrt(1 - p)` (`as_dist = FALSE` returns the proximities) |
| `depth_distance(x, y = NULL, rfObject)` | summed edge counts between leaves (divide by `num.trees` for the mean) |
| `terminal_nodes(x, rfObject)` | n x trees matrix of leaf ids |
| `ranger_forests_to_matrix(rfObject)`, `edges_between_terminal_nodes(rfObject)` | forest internals |
| `as_dist_object(x, n, method)` | converts a lower-triangle vector into a `dist` object |
| `generate_grid(t2e, grid_length = 250)` | time grid for survival curves |

Deprecated camelCase aliases (`distanceRandomForest`, `terminalNodes`, `weightedDistance`,
`asDistObject`) still exist. Use the snake_case names.
