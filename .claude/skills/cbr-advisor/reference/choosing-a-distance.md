# Choosing a Distance

The theory is in the *Methods* vignette, and the evidence in *Comparing the Approaches*
and the *Benchmark* article. This file is the condensed decision guide.

## Decision Tree

1. **What is the endpoint?**

   | Endpoint | Regression model | Forest | Baseline |
   |----------|------------------|--------|----------|
   | numeric | `LinearModel` | `BoostModel`, `RFModel` | `GowerModel` |
   | binary | `LogisticModel` | `BoostModel`, `RFModel` | `GowerModel` |
   | multi-class | none | `BoostModel`, `RFModel` | `GowerModel` |
   | survival (right-censored) | `CoxModel` | `BoostModel` (Cox objective), `RFModel` | `GowerModel` |
   | none / unknown | none | none | `GowerModel` or `gower_distance()` |

2. **Must the retrieved cases be justified (e.g. to clinicians)?** Prefer the regression
   model. Its distance decomposes into effects on the outcome:
   - a Cox distance `d` means the hazard ratio between the cases is at most `exp(d)`;
   - a logistic distance `d` bounds the odds ratio by `exp(d)`;
   - a linear distance `d` bounds the difference in expected outcome by `d`.

3. **Does the regression model fit?** Check:
   - `check_ph()` for a Cox model;
   - the functional form, adding splines with `rcs(x, 3-4)`;
   - plausible interactions, added with `a * b`.

   If it doesn't fit, or the relationships are complex or unknown:
   - use `BoostModel` (SHAP distance) if the distance should still be explained per
     feature on the outcome scale;
   - otherwise use `RFModel`.

4. **Are there many candidate features of unknown relevance?**
   - With regression, select the features first (`variable_selection()`). Noise
     coefficients shrink with more cases, but don't vanish on small data.
   - Don't rely on Gower here, because it weights every feature equally.
   - The forest also puts substantial weight on irrelevant *continuous* features on
     small data sets.

5. **Which forest distance?**

   | Distance | Use when | Trade-off |
   |----------|----------|-----------|
   | Depth (default) | you want a fine ranking of the neighbours | most expensive |
   | RF-GAP | the neighbours should explain the forest's prediction | values are all close to 1, only the order matters; refit after `add_cases()` |
   | original proximity | you need a classical Breiman proximity | many ties; biased for training cases |
   | OOB proximity | you need an in-sample proximity without in-bag bias | fewer trees per pair; refit after `add_cases()` |

6. **Always compare against the Gower baseline.** If a model-derived distance is not
   better than Gower on held-out data, its main value is interpretability.

## Advantages and Disadvantages

### Regression (contribution-space) distance

Pros:

- It weights features by their estimated effect, and irrelevant features get small
  weights.
- It is invariant to the units of measurement.
- It handles categorical features through their coefficients.
- The distance has a unit on the outcome scale.
- It is fully explainable per term.
- It is deterministic and fast.
- The model can be checked (`check_ph`) and features selected (`variable_selection`).
- Cases with the same risk *for different reasons* are far apart, because each term is
  compared on its own.

Cons:

- It is only as good as the model. Misspecification, missing interactions or violated
  proportional hazards give a misleading distance.
- Non-linearity and interactions must be specified by the user.
- The weights are unstable with few cases or collinear features.
- Two factor levels with similar coefficients are treated as near-identical.
- `LogisticModel` is binary only.

### Boosting (SHAP) distance

Pros:

- It learns non-linear effects and interactions.
- Like the regression distance, it bounds the difference of the predictions on the
  outcome, log-odds or log-hazard scale, and is explained per feature.
- For a linear model it reduces to the regression distance.
- It is cheap: O(n x m x p) once the SHAP values are computed.
- It needs no refit after `add_cases()`, and is deterministic without subsampling.

Cons:

- SHAP values are step functions, and they split interaction effects among the
  features involved.
- It inherits the boosted model's overfitting. On 160 lung cases with 5 noise features,
  about 40% of its weight went to noise, and it had the least stable neighbourhoods
  under 90% subsampling (Jaccard overlap 0.45, against 0.72 for Cox and 0.98 for
  Gower).
- It needs tuning: choose `nrounds` and `max_depth` (1-3) by cross-validation with
  `xgboost::xgb.cv()` and early stopping (code in the *Methods* vignette). With many
  fixed rounds, the splits in noise features become distance. The 40% above came from
  100 fixed rounds; on very small data (lung) tuning does not make it stable.
- It needs the suggested package xgboost.

### Random forest distances

Pros:

- No model specification is needed: non-linear effects and interactions are found
  automatically.
- It handles mixed feature types, and is invariant to monotone transformations.
- RF-GAP matches the forest's own predictions.

Cons:

- There is no outcome-scale unit, and explanations are counts of split variables.
- It depends on the seed and on tuning (`num.trees`, `mtry`, `min.node.size`).
- Splits favour features with many split points, so irrelevant continuous features get
  substantial weight on small data. Larger `min.node.size` did not fix this in the
  vignette.
- The original proximity is biased and coarse.
- It costs more: about `n x m x trees` operations.
- OOB and RF-GAP need a refit after the case base changes.

### Gower distance

Pros:

- No model and no outcome are needed.
- It is transparent and deterministic.
- It handles missing values pair by pair.
- Weights can encode expert knowledge.
- It is very stable under resampling.

Cons:

- Every feature counts equally unless weighted by hand. Irrelevant features dilute the
  distance, and it lost the most accuracy with noise features in the benchmark.
- Range scaling makes it sensitive to outliers.
- Binary features dominate: switching a binary feature costs 1, the maximum.
- It has no unit on the outcome scale.

## Choosing `k`

`k` trades bias (too many dissimilar cases) against variance (too few cases). Evaluate a
grid on held-out data:

- **Survival:** start with `k` of 10–40, and use `evaluate_survival()` (higher C, lower
  IBS).
- **Classification and regression:** start with `k` of 5–20, and use `evaluate()`.
- **`weighted = TRUE`:** tricube weights make the result less sensitive to a `k` that is
  too large.
