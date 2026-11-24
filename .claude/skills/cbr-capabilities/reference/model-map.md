# Model Map (CaseBasedReasoning 0.5.x)

All model classes are R6 generators exported from the package. Verify against the
installed version before relying on this list:
`Rscript -e 'library(CaseBasedReasoning); print(ls("package:CaseBasedReasoning"))'`.

Class hierarchy:

```
CBRBase                  retrieval, reuse, revise, retain (all shared methods)
├── RegressionModel      variable_selection(), contribution-space distance
│   ├── LinearModel      rms::ols
│   ├── LogisticModel    rms::lrm
│   └── CoxModel         rms::cph, check_ph()
├── BoostModel           xgboost, SHAP distance, shap_values()
├── RFModel              ranger forest, set_distance_method()
└── GowerModel           Gower distance
```

## Regression models: `LinearModel`, `LogisticModel`, `CoxModel`

Constructor: `Model$new(formula, data)`.

- The formula can contain any **rms** term, such as `rcs(age, 4)` (restricted cubic
  spline), `pol(x, 2)`, `catg(x)`, or interactions `a * b`.
- `CoxModel` needs `Surv(time, status) ~ ...`, with status 0/1.
- `LogisticModel` supports binary endpoints only.

Distance: for each model term `t`, the contribution to the linear predictor is
`c_t(x) = X_t(x) %*% beta_t`. Then `d(x_i, x_j) = sum_t |c_t(x_i) - c_t(x_j)|`.

- For a numeric main effect, the term adds `|beta| * |x_i - x_j|`.
- For a factor, it adds `|beta_level(i) - beta_level(j)|`.
- `d` bounds the difference of the linear predictors. In a Cox model, `exp(d)` bounds
  the hazard ratio between the two cases; in a logistic model, it bounds the odds ratio.

Fitted objects:

- `$model_fit` holds the rms fit.
- `$weights` holds the coefficients per term.

| Method | Purpose |
|--------|---------|
| `$variable_selection(update = FALSE, ...)` | `rms::fastbw` backward selection; with `update = TRUE` the formula is restricted to the selected terms (refit afterwards) |
| `$check_ph()` | Cox only: Schoenfeld-residual check of proportional hazards (`survival::cox.zph`) with plots |

## `BoostModel`

Constructor: `BoostModel$new(formula, data, nrounds = 100, params = list(eta = 0.1, max_depth = 3))`.

- It needs the suggested package **xgboost**.
- The endpoint sets the objective:

  | Endpoint | Objective |
  |----------|-----------|
  | `Surv(time, status)` | `survival:cox` |
  | two classes (factor, character, logical or 0/1) | `binary:logistic` |
  | more than two classes | `multi:softprob` |
  | numeric | `reg:squarederror` |

- `params` is passed to `xgboost::xgb.train`. A `params$objective` you set overrides
  the default; `nthread` defaults to 1.
- Only the variables of the formula are used. Transformations and interactions are
  ignored, because the trees learn them themselves.
- Unordered factors are one-hot encoded and their SHAP values summed per variable.
  Ordered factors are used as their ranks.

Distance: `d(x_i, x_j) = sum_k |phi_k(x_i) - phi_k(x_j)|`, where `phi_k` are the exact
TreeSHAP values (`predict(..., predcontrib = TRUE)`).

- The SHAP values are on the model's margin scale: the outcome, the log odds, or the log
  relative hazard.
- `|f(x_i) - f(x_j)| <= d`. With the Cox objective, `exp(d)` bounds the hazard ratio.
- For a linear model, `phi_k = beta_k (x_k - mean)`, so the distance equals the
  regression distance. With `params = list(booster = "gblinear", ...)` it reproduces
  `LinearModel`.
- For multi-class models, the SHAP values of all classes are used; terms are named
  `"var [class]"`.

| Method | Purpose |
|--------|---------|
| `$shap_values(data)` | SHAP matrix (cases x variables) with attribute `bias`; `rowSums + bias` equals the margin |

Notes:

- The model is deterministic without row or column subsampling.
- `add_cases()` needs no refit.
- The SHAP values are step functions of each feature: a small difference across a split
  counts fully.
- On small data the distance overfits, giving weight to noise and producing unstable
  neighbours. Choose `nrounds` and `max_depth` by cross-validation
  (`xgboost::xgb.cv()` with early stopping; see the *Methods* vignette), and regularise
  with `eta`, `min_child_weight` and `lambda`.

## `RFModel`

Constructor: `RFModel$new(formula, data, ...)`.

- `...` is passed to `ranger::ranger`, e.g. `num.trees`, `mtry`, `min.node.size`, `seed`.
- `write.forest = TRUE` is forced; `keep.inbag = TRUE` is the default.
- Classification, regression and survival (`Surv()` formula) forests are supported.

`$set_distance_method(method = "Depth", proximity_type = "original")`:

| `method` | `proximity_type` | Distance |
|----------|------------------|----------|
| `"Depth"` (default) | — | mean number of edges between the two cases' leaves over the trees (Englund & Verikas, 2012) |
| `"Proximity"` | `"original"` | `sqrt(1 - p)`, where `p` is the share of trees in which both cases share a leaf (Breiman) |
| `"Proximity"` | `"oob"` | as above, counting only trees where both cases are out-of-bag |
| `"Proximity"` | `"rfgap"` | RF-GAP (Rhodes, Cutler & Moon, 2023): the proximity-weighted mean of the training outcomes equals the forest prediction; distances lie close to 1, and only their order matters |

Notes:

- OOB and RF-GAP need the in-bag counts of the cases the forest was grown on. After
  `add_cases()` / `remove_cases()` they error until `$fit()` is called again.
- `explain_match()` counts the split variables at which the two cases' paths diverge.
  Attribute `same_leaf` is the proximity.
- Distances depend on the random seed: call `set.seed()` before `$fit()`, or pass `seed =`.

## `GowerModel`

Constructor: `GowerModel$new(formula, data, weights = NULL)`.

- The endpoint is optional (`GowerModel$new(~ x1 + x2, data)` works for retrieval). It is
  used only by the reuse, revise and retain methods; the distance ignores it.
- `weights` are non-negative per-variable weights: either unnamed (one per variable) or
  named.

Distance (Gower, 1971): a weighted mean of per-variable distances in [0, 1].

| Variable type | Per-variable distance |
|---------------|-----------------------|
| numeric | absolute difference divided by the training range |
| ordered factor | rank difference divided by (number of levels − 1) |
| other factor | 0 if equal, 1 otherwise |

Variables that are missing in either case are skipped for that pair.

`$model_fit$ranges` stores the training ranges. Standalone version:
`gower_distance(x, y = NULL, weights = NULL, ranges = NULL)`.

## Which model? (capability view)

| Need | Model |
|------|-------|
| Distance that is interpretable on the outcome scale | regression model for the endpoint type |
| Unknown non-linearities and interactions, explained per feature on the outcome scale | `BoostModel` |
| Unknown non-linearities and interactions | `RFModel` |
| Retrieval that matches the forest's predictions | `RFModel` with `proximity_type = "rfgap"` |
| No outcome model, or a baseline | `GowerModel` |
| Multi-class endpoint | `RFModel` or `GowerModel` (`LogisticModel` is binary only) |

For data-specific advice (assumptions, noise, stability, choosing `k`), use
**cbr-advisor** → `reference/choosing-a-distance.md`.
