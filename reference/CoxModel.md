# Cox-Beta Model for Case-Based-Reasoning

Cox-Beta Model for Case-Based-Reasoning

Cox-Beta Model for Case-Based-Reasoning

## Details

Regression beta coefficients obtained from a CPH regression model fitted
on the training data are used for building a weighted distance measure
between train and test data. Afterwards, we will use these weights for
calculating a (n x m)-distance matrix, where n is the number of
observations in the training data, and m is the number of observations
of the test data. The user can use this distance matrix for further
cluster analysis or for extracting for each test observation k (=
1,...,l) similar cases from the train data. We use the rms-package for
model fitting, variable selection, and checking model assumptions. If
the user omits the test data, this functions returns a n x n-distance
matrix.

## Super classes

[`CaseBasedReasoning::CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
-\>
[`CaseBasedReasoning::RegressionModel`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.md)
-\> `CoxModel`

## Public fields

- `model`:

  the statistical model

- `model_params`:

  rms arguments

## Methods

### Public methods

- [`CoxModel$check_ph()`](#method-CoxModel-check_ph)

- [`CoxModel$clone()`](#method-CoxModel-clone)

Inherited methods

- [`CaseBasedReasoning::CBRBase$calc_distance_matrix()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-calc_distance_matrix)
- [`CaseBasedReasoning::CBRBase$evaluate_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-evaluate_survival)
- [`CaseBasedReasoning::CBRBase$get_similar_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_similar_cases)
- [`CaseBasedReasoning::CBRBase$initialize()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-initialize)
- [`CaseBasedReasoning::CBRBase$predict_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_survival)
- [`CaseBasedReasoning::RegressionModel$fit()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-fit)
- [`CaseBasedReasoning::RegressionModel$print()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-print)
- [`CaseBasedReasoning::RegressionModel$variable_selection()`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.html#method-variable_selection)

------------------------------------------------------------------------

### Method `check_ph()`

Check proportional hazard assumption graphically

#### Usage

    CoxModel$check_ph()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CoxModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
