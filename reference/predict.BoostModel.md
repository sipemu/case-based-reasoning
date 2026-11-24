# Predict method for BoostModel

Predict method for BoostModel

## Usage

``` r
# S3 method for class 'BoostModel'
predict(
  object,
  newdata,
  k = NULL,
  type = c("cases", "outcome", "survival"),
  ...
)
```

## Arguments

- object:

  A `BoostModel` R6 object

- newdata:

  Query data of class data.frame

- k:

  Number of similar cases. Default: 1 for `type = "cases"`, 10
  otherwise.

- type:

  `"cases"` (default): the similar cases (`$get_similar_cases()`);
  `"outcome"`: predicted class or numeric outcome
  (`$predict_outcome()`); `"survival"`: predicted survival probabilities
  (`$predict_survival()`).

- ...:

  Further arguments passed to the method selected by `type`

## Value

A data.frame of similar cases, a data.frame of predictions, or a matrix
of survival probabilities
