# Gradient Boosting with a SHAP Distance for Case-Based Reasoning

Gradient Boosting with a SHAP Distance for Case-Based Reasoning

Gradient Boosting with a SHAP Distance for Case-Based Reasoning

## Details

Fits a gradient-boosted tree model with **xgboost** and measures the
distance between two cases in the space of their SHAP values (Lundberg
et al., 2020). With \\\phi_k(x)\\ the SHAP value of variable \\k\\, i.e.
its contribution to the prediction of case \\x\\ on the margin scale of
the model (outcome, log odds or log relative hazard), \$\$d(x_i, x_j) =
\sum_k \|\phi_k(x_i) - \phi_k(x_j)\|.\$\$ This is the contribution-space
distance of the regression models with the variables as terms: for a
linear model, \\\phi_k(x) = \beta_k (x_k - \bar x_k)\\, and the distance
is the weighted distance of Dippon et al. (2002). Because the SHAP
values add up to the model's prediction, the distance bounds the
difference of the predictions on the margin scale; for the Cox
objective, \\e^{d}\\ bounds the hazard ratio of the two cases.

The endpoint determines the objective: `Surv(time, status)` uses
`"survival:cox"`, two classes (factor, character, logical or 0/1)
`"binary:logistic"`, more classes `"multi:softprob"` (the SHAP values of
all classes are used), and numeric endpoints `"reg:squarederror"`. Only
the variables of the formula are used, not transformations or
interactions: the trees find non-linear effects and interactions
themselves. Unordered factors are one-hot encoded and their SHAP values
summed per variable; ordered factors are used as their ranks.

Every split of the model is part of the distance: choose `nrounds` and
`max_depth` by cross-validation
([`xgboost::xgb.cv()`](https://rdrr.io/pkg/xgboost/man/xgb.cv.html) with
early stopping) rather than by default, otherwise splits in irrelevant
features become distance. The *Methods* vignette shows how.

Without row or column subsampling (the default), the model and the
distance are deterministic. New cases (`add_cases()`) need no refit:
their SHAP values are computed with the fitted model.

## References

Lundberg, S. M. et al. (2020). From local explanations to global
understanding with explainable AI for trees. Nature Machine
Intelligence, 2, 56–67.
[doi:10.1038/s42256-019-0138-9](https://doi.org/10.1038/s42256-019-0138-9)

Chen, T. and Guestrin, C. (2016). XGBoost: A scalable tree boosting
system. Proceedings of KDD 2016, 785–794.
[doi:10.1145/2939672.2939785](https://doi.org/10.1145/2939672.2939785)

## Super class

[`CaseBasedReasoning::CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
-\> `BoostModel`

## Public fields

- `model`:

  the learner

- `model_params`:

  xgboost parameters (`params`, `nrounds`)

## Methods

### Public methods

- [`BoostModel$new()`](#method-BoostModel-new)

- [`BoostModel$print()`](#method-BoostModel-print)

- [`BoostModel$fit()`](#method-BoostModel-fit)

- [`BoostModel$shap_values()`](#method-BoostModel-shap_values)

- [`BoostModel$clone()`](#method-BoostModel-clone)

Inherited methods

- [`CaseBasedReasoning::CBRBase$add_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-add_cases)
- [`CaseBasedReasoning::CBRBase$assess_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-assess_cases)
- [`CaseBasedReasoning::CBRBase$calc_distance_matrix()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-calc_distance_matrix)
- [`CaseBasedReasoning::CBRBase$evaluate()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-evaluate)
- [`CaseBasedReasoning::CBRBase$evaluate_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-evaluate_survival)
- [`CaseBasedReasoning::CBRBase$explain_match()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-explain_match)
- [`CaseBasedReasoning::CBRBase$get_case_base()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_case_base)
- [`CaseBasedReasoning::CBRBase$get_counterfactual_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_counterfactual_cases)
- [`CaseBasedReasoning::CBRBase$get_similar_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_similar_cases)
- [`CaseBasedReasoning::CBRBase$predict_outcome()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_outcome)
- [`CaseBasedReasoning::CBRBase$predict_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_survival)
- [`CaseBasedReasoning::CBRBase$remove_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-remove_cases)

------------------------------------------------------------------------

### Method `new()`

Initialize a gradient boosting model for searching similar cases.

#### Usage

    BoostModel$new(
      formula,
      data,
      nrounds = 100,
      params = list(eta = 0.1, max_depth = 3)
    )

#### Arguments

- `formula`:

  Object of class formula or character, e.g. `y ~ x1 + x2` or
  `Surv(time, status) ~ .`.

- `data`:

  Training data of class data.frame

- `nrounds`:

  number of boosting rounds

- `params`:

  list of xgboost parameters, e.g. `eta`, `max_depth`, `lambda`;
  `objective` is set from the endpoint unless given.

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Prints information of the initialized object

#### Usage

    BoostModel$print()

------------------------------------------------------------------------

### Method `fit()`

Fit the boosted trees.

#### Usage

    BoostModel$fit()

------------------------------------------------------------------------

### Method `shap_values()`

SHAP values of cases: one column per variable (for multi-class models,
per variable and class), on the margin scale of the model.

#### Usage

    BoostModel$shap_values(data)

#### Arguments

- `data`:

  data.frame with the variables of the model

#### Returns

A matrix with attribute `bias` (the expected margin).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    BoostModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
# \donttest{
if (requireNamespace("xgboost", quietly = TRUE)) {
  library(survival)
  lung2 <- na.omit(lung[, c("time", "status", "age", "sex", "ph.ecog")])
  lung2$status <- lung2$status - 1
  m <- BoostModel$new(Surv(time, status) ~ age + sex + ph.ecog, lung2, nrounds = 50)
  m$fit()
  m$get_similar_cases(lung2[1:2, ], k = 3)
  m$explain_match(lung2[1, ], lung2[2, ])
}
#> 
#> Attaching package: ‘survival’
#> The following object is masked from ‘package:rms’:
#> 
#>     cluster
#>      term query_contribution case_contribution    distance      share
#> 1     age         -0.2961400         0.1965927 0.492732689 0.95507495
#> 2 ph.ecog         -0.2261617        -0.2393686 0.013206914 0.02559926
#> 3     sex          0.2666522         0.2566818 0.009970367 0.01932579
# }
```
