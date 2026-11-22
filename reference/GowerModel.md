# Gower Distance Model for Case-Based-Reasoning

Gower Distance Model for Case-Based-Reasoning

Gower Distance Model for Case-Based-Reasoning

## Details

A model-free case base: the distance between cases is the Gower distance
([`gower_distance`](https://sipemu.github.io/case-based-reasoning/reference/gower_distance.md))
of the variables on the right-hand side of the formula, optionally
weighted. The endpoint (left-hand side) is not used for the distance,
but for `predict_outcome()`, `predict_survival()`, `evaluate()` and
counterfactual cases. Use it as a baseline for the model-derived
distances of the other models, or with expert-defined weights.

Ranges of numeric variables are taken from the training cases, so that
distances of query cases do not depend on each other.

## References

Gower, J. C. (1971). A general coefficient of similarity and some of its
properties. Biometrics, 27(4), 857–871.
[doi:10.2307/2528823](https://doi.org/10.2307/2528823)

## Super class

[`CaseBasedReasoning::CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
-\> `GowerModel`

## Public fields

- `model`:

  the distance

- `weights`:

  variable weights (named numeric)

## Methods

### Public methods

- [`GowerModel$new()`](#method-GowerModel-new)

- [`GowerModel$print()`](#method-GowerModel-print)

- [`GowerModel$fit()`](#method-GowerModel-fit)

- [`GowerModel$clone()`](#method-GowerModel-clone)

Inherited methods

- [`CaseBasedReasoning::CBRBase$calc_distance_matrix()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-calc_distance_matrix)
- [`CaseBasedReasoning::CBRBase$evaluate()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-evaluate)
- [`CaseBasedReasoning::CBRBase$evaluate_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-evaluate_survival)
- [`CaseBasedReasoning::CBRBase$explain_match()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-explain_match)
- [`CaseBasedReasoning::CBRBase$get_counterfactual_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_counterfactual_cases)
- [`CaseBasedReasoning::CBRBase$get_similar_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_similar_cases)
- [`CaseBasedReasoning::CBRBase$predict_outcome()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_outcome)
- [`CaseBasedReasoning::CBRBase$predict_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_survival)

------------------------------------------------------------------------

### Method `new()`

Initialize a Gower distance model.

#### Usage

    GowerModel$new(formula, data, weights = NULL)

#### Arguments

- `formula`:

  Object of class formula or character, e.g. `y ~ .` or
  `Surv(time, status) ~ x1 + x2`.

- `data`:

  Training data of class data.frame

- `weights`:

  variable weights, see
  [`gower_distance`](https://sipemu.github.io/case-based-reasoning/reference/gower_distance.md)

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Prints information of the initialized object

#### Usage

    GowerModel$print()

------------------------------------------------------------------------

### Method `fit()`

"Fit" the model: prepare the case base and store the ranges of the
numeric variables.

#### Usage

    GowerModel$fit()

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    GowerModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.

## Examples

``` r
m <- GowerModel$new(Species ~ ., iris[-(1:3), ])
m$fit()
m$get_similar_cases(iris[1:3, ], k = 2)
#>    Sepal.Length Sepal.Width Petal.Length Petal.Width Species     scDist caseId
#> 18          5.1         3.5          1.4         0.3  setosa 0.01041667      1
#> 28          5.2         3.5          1.5         0.2  setosa 0.01118173      2
#> 35          4.9         3.1          1.5         0.2  setosa 0.01465395      1
#> 26          5.0         3.0          1.6         0.2  setosa 0.01541902      2
#> 48          4.6         3.2          1.4         0.2  setosa 0.01118173      1
#> 30          4.7         3.2          1.6         0.2  setosa 0.01271186      2
m$predict_outcome(iris[1:3, ], k = 5)
#>   prediction prob_setosa prob_versicolor prob_virginica
#> 1     setosa           1               0              0
#> 2     setosa           1               0              0
#> 3     setosa           1               0              0
```
