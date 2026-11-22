# Linear Regression Model for Case-Based-Reasoning

Linear Regression Model for Case-Based-Reasoning

Linear Regression Model for Case-Based-Reasoning

## Super classes

[`CaseBasedReasoning::CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
-\>
[`CaseBasedReasoning::RegressionModel`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.md)
-\> `LinearModel`

## Public fields

- `model`:

  the statistical model

## Methods

### Public methods

- [`LinearModel$clone()`](#method-LinearModel-clone)

Inherited methods

- [`CaseBasedReasoning::CBRBase$calc_distance_matrix()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-calc_distance_matrix)
- [`CaseBasedReasoning::CBRBase$get_similar_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_similar_cases)
- [`CaseBasedReasoning::CBRBase$initialize()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-initialize)
- [`CaseBasedReasoning::RegressionModel$fit()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-fit)
- [`CaseBasedReasoning::RegressionModel$print()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-print)
- [`CaseBasedReasoning::RegressionModel$variable_selection()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-variable_selection)

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    LinearModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
