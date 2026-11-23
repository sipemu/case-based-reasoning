# RandomForest Model for Searching Similar Cases

RandomForest Model for Searching Similar Cases

RandomForest Model for Searching Similar Cases

## Details

This class uses the proximity or depth matrix of the RandomForest
algorithm as a similarity matrix of training and query observations. By
default all cases with at least one missing values are dropped from
learning, calculating the distance matrix and searching for similar
cases.

## References

Englund, C. and Verikas, A. (2012). A novel approach to estimate
proximity in a random forest: An exploratory study. Expert Systems with
Applications, 39(17), 13046–13050.
[doi:10.1016/j.eswa.2012.05.094](https://doi.org/10.1016/j.eswa.2012.05.094)

## Super class

[`CaseBasedReasoning::CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
-\> `RFModel`

## Public fields

- `model`:

  the statistical model

- `model_params`:

  model arguments

- `dist_method`:

  Distance method

- `proximity_type`:

  Proximity type for `dist_method = "Proximity"`: `"original"`, `"oob"`
  or `"rfgap"` (see
  [`proximity_distance`](https://sipemu.github.io/case-based-reasoning/reference/proximity_distance.md)).

## Methods

### Public methods

- [`RFModel$print()`](#method-RFModel-print)

- [`RFModel$new()`](#method-RFModel-new)

- [`RFModel$fit()`](#method-RFModel-fit)

- [`RFModel$set_distance_method()`](#method-RFModel-set_distance_method)

- [`RFModel$clone()`](#method-RFModel-clone)

Inherited methods

- [`CaseBasedReasoning::CBRBase$calc_distance_matrix()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-calc_distance_matrix)
- [`CaseBasedReasoning::CBRBase$evaluate_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-evaluate_survival)
- [`CaseBasedReasoning::CBRBase$explain_match()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-explain_match)
- [`CaseBasedReasoning::CBRBase$get_counterfactual_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_counterfactual_cases)
- [`CaseBasedReasoning::CBRBase$get_similar_cases()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-get_similar_cases)
- [`CaseBasedReasoning::CBRBase$predict_survival()`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.html#method-predict_survival)

------------------------------------------------------------------------

### Method [`print()`](https://rdrr.io/r/base/print.html)

Prints information of the initialized object

#### Usage

    RFModel$print()

------------------------------------------------------------------------

### Method `new()`

Initialize a RandomForest object for searching similar cases.

#### Usage

    RFModel$new(formula, data, ...)

#### Arguments

- `formula`:

  Object of class formula or character describing the model fit.

- `data`:

  Training data of class data.frame

- `...`:

  ranger RandomForest arguments. `write.forest` is always set to `TRUE`;
  `verbose` defaults to `FALSE`.

------------------------------------------------------------------------

### Method `fit()`

Fit the RandomForest

#### Usage

    RFModel$fit()

------------------------------------------------------------------------

### Method `set_distance_method()`

Set the distance method. Available are Proximity and Depth

#### Usage

    RFModel$set_distance_method(method = "Depth", proximity_type = "original")

#### Arguments

- `method`:

  Distance calculation method (default: Depth)

- `proximity_type`:

  Proximity type for `method = "Proximity"`: `"original"` (default),
  `"oob"` or `"rfgap"`. The latter two use the forest's in-bag counts;
  for a query given to `get_similar_cases()` or `calc_distance_matrix()`
  the query is treated as new data, without a query
  (`calc_distance_matrix()`) the in-sample, out-of-bag version is
  computed.

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    RFModel$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
