# Root class for Regression Models, e.g., CPH, logistic, and linear regression

Root class for Regression Models, e.g., CPH, logistic, and linear
regression

Root class for Regression Models, e.g., CPH, logistic, and linear
regression

## Super class

[`CaseBasedReasoning::CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
-\> `RegressionModel`

## Public fields

- `model_params`:

  rms arguments

- `weights`:

  Weights for distance calculation

## Methods

### Public methods

- [`RegressionModel$print()`](#method-RegressionModel-print)

- [`RegressionModel$variable_selection()`](#method-RegressionModel-variable_selection)

- [`RegressionModel$fit()`](#method-RegressionModel-fit)

- [`RegressionModel$clone()`](#method-RegressionModel-clone)

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
- [`CaseBasedReasoning::CBRBase$initialize()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-initialize)
- [`CaseBasedReasoning::CBRBase$predict_outcome()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_outcome)
- [`CaseBasedReasoning::CBRBase$predict_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_survival)
- [`CaseBasedReasoning::CBRBase$remove_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-remove_cases)

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Prints information of the initialized object

#### Usage

    RegressionModel$print()

------------------------------------------------------------------------

### Method `variable_selection()`

Fast backward variable selection with penalization
([`rms::fastbw`](https://rdrr.io/pkg/rms/man/fastbw.html))

#### Usage

    RegressionModel$variable_selection(update = FALSE, ...)

#### Arguments

- `update`:

  If `TRUE`, restrict the model's formula and terms to the selected
  variables. The model must then be fitted again with `$fit()`.

- `...`:

  Further arguments passed to
  [`rms::fastbw`](https://rdrr.io/pkg/rms/man/fastbw.html), e.g. `rule`
  or `sls`.

#### Returns

Character vector of the selected (retained) variables.

------------------------------------------------------------------------

### Method `fit()`

Fit the regression model

#### Usage

    RegressionModel$fit()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    RegressionModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
