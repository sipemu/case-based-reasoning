---
name: cbr-capabilities
description: |
  Discover the CaseBasedReasoning R package's capabilities: list the model classes
  (CoxModel, LinearModel, LogisticModel, BoostModel, RFModel, GowerModel), their R6 methods and
  call signatures, the distance functions, and which method covers which step of the
  case-based reasoning cycle (retrieve, reuse, revise, retain). Use this skill whenever
  a user asks "what can CaseBasedReasoning do?", "which model or distance can I use for
  X?", "what's the signature of Y?", or needs API discovery for similar-case retrieval,
  k-NN survival prediction, counterfactual cases, or case-base maintenance in R.
  Capability discovery only. Choosing and checking a distance for concrete data, and
  interpreting results, belong to the cbr-advisor skill.
---

# CaseBasedReasoning Capabilities Skill

This skill answers **"what exists and how do I call it?"** for the CaseBasedReasoning R
package. Base answers on the package's `NAMESPACE` and R6 class definitions, and never
make up a method or argument. Hand off to the **cbr-advisor** skill for running an
analysis, choosing a distance for a data set, or reading results.

## Skill Boundary

- **In scope:** exported classes and functions, R6 methods and their signatures, the
  model/distance inventory, mapping CBR steps to methods.
- **Out of scope (→ cbr-advisor):** which distance suits *this* data, choosing `k`,
  checking model assumptions, interpreting `evaluate()` or `assess_cases()` output.

## Source of Truth: verify before answering

The API changes between versions. Check it against the installed package, not memory:

```r
# exported symbols (R6 generators and functions)
Rscript -e 'library(CaseBasedReasoning); print(ls("package:CaseBasedReasoning"))'

# public methods of a model class, including inherited ones
Rscript -e 'library(CaseBasedReasoning); m <- CoxModel$new(survival::Surv(futime, fustat) ~ age, survival::ovarian); print(names(m))'

# signature of one method (methods are defined in the base classes)
Rscript -e 'ns <- asNamespace("CaseBasedReasoning"); print(args(ns$CBRBase$public_methods$get_similar_cases))'
```

Without loading the package, read `NAMESPACE` and the R6 definitions in `R/`:

```bash
grep -E "^export\(" NAMESPACE | sed -E 's/export\((.*)\)/\1/' | sort
grep -nE "^ +[a-z_]+ = function\(" R/CBRBase.R R/RegressionModel.R R/RFModel.R R/gower.R R/boost.R
```

Online reference: <https://sipemu.github.io/case-based-reasoning/reference/index.html>.

## The Pattern

Every model is an R6 class with the same life cycle:

```r
model <- CoxModel$new(Surv(time, status) ~ age + sex, train)  # 1. define
model$fit()                                                   # 2. learn the distance
model$get_similar_cases(query, k = 5)                         # 3. use it
```

`fit()` drops training cases with missing values (with a warning) and converts
characters to factors. Queries are validated against the training data: factor levels
are matched by name, and unknown levels and missing values are errors.

## Model Classes

| Class | Endpoint | Distance | Extra methods |
|-------|----------|----------|---------------|
| `LinearModel` | numeric | contribution-space distance from an `rms::ols` fit | `variable_selection()` |
| `LogisticModel` | binary (0/1, logical, two-level factor) | contribution-space distance from `rms::lrm` | `variable_selection()` |
| `CoxModel` | survival, `Surv(time, status)` | contribution-space distance from `rms::cph` | `variable_selection()`, `check_ph()` |
| `BoostModel` | numeric, class, or survival | SHAP distance from an xgboost model (needs the suggested package xgboost) | `shap_values()` |
| `RFModel` | numeric, class, or survival | random forest (`ranger`): depth (default) or proximity (original / OOB / RF-GAP) | `set_distance_method()` |
| `GowerModel` | any, or none (`~ x1 + x2`) | Gower distance, optional weights | none |

See `reference/model-map.md` for constructor arguments, distance definitions and notes.

## CBR Cycle → Methods

| Step | Methods (all model classes) |
|------|-----------------------------|
| Retrieve | `get_similar_cases()`, `calc_distance_matrix()`, `explain_match()`, `predict(type = "cases")` |
| Reuse | `predict_outcome()`, `predict_survival()`, `get_counterfactual_cases()`, `predict(type = "outcome" / "survival")` |
| Revise | `evaluate()`, `evaluate_survival()`, `check_ph()` (Cox only) |
| Retain | `add_cases()`, `remove_cases()`, `assess_cases()`, `get_case_base()` |

See `reference/function-map.md` for every method's signature, return value and
standalone distance function.

## Method-for-Task Routing (quick answers)

| User goal | Point them at |
|-----------|---------------|
| "Find similar patients/cases" | any model → `$fit()` → `$get_similar_cases(query, k)` |
| "Similar cases for survival data" | `CoxModel` (interpretable) or `RFModel` with a `Surv()` formula |
| "Predict a class or number from neighbours" | `$predict_outcome(query, k, weighted)`; score with `$evaluate(test, k)` |
| "Predict a survival curve from neighbours" | `$predict_survival(query, k, times)`; score with `$evaluate_survival(test, k)` |
| "Why are these two cases similar?" | `$explain_match(query, case)` |
| "Similar case with a different outcome" | `$get_counterfactual_cases(query, k, horizon)` |
| "Non-linear effects / interactions" | regression formula with `rcs(x, 4)` or `a * b`, `BoostModel` (SHAP distance, explained per feature), or `RFModel` |
| "Distance without an outcome model" | `GowerModel$new(~ x1 + x2, data)` or `gower_distance(x, y)` |
| "Distance matrix for clustering / heatmap" | `$calc_distance_matrix()` (n x n) or `$calc_distance_matrix(query)` (n x m) |
| "Add new solved cases" | `$add_cases(newdata, refit = FALSE)` |
| "Find noisy / redundant cases" | `$assess_cases(k, horizon)`, then `$remove_cases()` |
| "Leave-one-out retrieval" | `exclude_self = TRUE` in `get_similar_cases()` / `predict_outcome()` |
| "RF distance on my own ranger forest" | `distance_random_forest(x, y, rfObject, method, proximity_type)` |

Beyond "which one" and into "is it appropriate for my data", hand off to
**cbr-advisor**.
