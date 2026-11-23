# Logistic Regression Model for Case-Based-Reasoning

Logistic Regression Model for Case-Based-Reasoning

Logistic Regression Model for Case-Based-Reasoning

## Super classes

[`CaseBasedReasoning::CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
-\>
[`CaseBasedReasoning::RegressionModel`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.md)
-\> `LogisticModel`

## Public fields

- `model`:

  the statistical model

## Methods

### Public methods

- [`LogisticModel$clone()`](#method-LogisticModel-clone)

Inherited methods

- [`CaseBasedReasoning::CBRBase$calc_distance_matrix()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-calc_distance_matrix)
- [`CaseBasedReasoning::CBRBase$evaluate_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-evaluate_survival)
- [`CaseBasedReasoning::CBRBase$explain_match()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-explain_match)
- [`CaseBasedReasoning::CBRBase$get_counterfactual_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_counterfactual_cases)
- [`CaseBasedReasoning::CBRBase$get_similar_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_similar_cases)
- [`CaseBasedReasoning::CBRBase$initialize()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-initialize)
- [`CaseBasedReasoning::CBRBase$predict_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_survival)
- [`CaseBasedReasoning::RegressionModel$fit()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-fit)
- [`CaseBasedReasoning::RegressionModel$print()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-print)
- [`CaseBasedReasoning::RegressionModel$variable_selection()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-variable_selection)

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    LogisticModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
