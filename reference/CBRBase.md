# Root class for common functionality of this package

Root class for common functionality of this package

Root class for common functionality of this package

## References

Lowsky, D. J. et al. (2013). A K-nearest neighbors survival probability
prediction method. Statistics in Medicine, 32(12), 2062–2069.
[doi:10.1002/sim.5673](https://doi.org/10.1002/sim.5673)

Uno, H. et al. (2011). On the C-statistics for evaluating overall
adequacy of risk prediction procedures with censored survival data.
Statistics in Medicine, 30(10), 1105–1117.
[doi:10.1002/sim.4154](https://doi.org/10.1002/sim.4154)

Graf, E. et al. (1999). Assessment and comparison of prognostic
classification schemes for survival data. Statistics in Medicine,
18(17-18), 2529–2545.

## Public fields

- `model`:

  the statistical model

- `data`:

  training data

- `model_fit`:

  trained object

- `formula`:

  Object of class formula or character describing the model fit

- `terms`:

  terms of the formula (term labels, e.g. `"rcs(age, 3)"`)

- `variables`:

  variables used by the terms of the formula

- `endpoint`:

  Target variable

- `dist_matrix`:

  A matrix with distances

- `order_matrix`:

  A matrix with the order indices for similar cases search

## Active bindings

- `endPoint`:

  Deprecated: use `endpoint` instead.

- `distMat`:

  Deprecated: use `dist_matrix` instead.

- `orderMat`:

  Deprecated: use `order_matrix` instead.

## Methods

### Public methods

- [`CBRBase$new()`](#method-CBRBase-new)

- [`CBRBase$fit()`](#method-CBRBase-fit)

- [`CBRBase$calc_distance_matrix()`](#method-CBRBase-calc_distance_matrix)

- [`CBRBase$get_similar_cases()`](#method-CBRBase-get_similar_cases)

- [`CBRBase$predict_survival()`](#method-CBRBase-predict_survival)

- [`CBRBase$evaluate_survival()`](#method-CBRBase-evaluate_survival)

- [`CBRBase$clone()`](#method-CBRBase-clone)

------------------------------------------------------------------------

### Method `new()`

Initialize object for searching similar cases

#### Usage

    CBRBase$new(formula, data)

#### Arguments

- `formula`:

  Object of class formula or character describing the model fit

- `data`:

  Training data of class data.frame

------------------------------------------------------------------------

### Method `fit()`

Fit the Model

#### Usage

    CBRBase$fit()

------------------------------------------------------------------------

### Method `calc_distance_matrix()`

Calculates the distance matrix

#### Usage

    CBRBase$calc_distance_matrix(query = NULL)

#### Arguments

- `query`:

  Query data of class data.frame

------------------------------------------------------------------------

### Method `get_similar_cases()`

Extracts similar cases

#### Usage

    CBRBase$get_similar_cases(
      query,
      k = 1,
      add_distance = TRUE,
      merge = FALSE,
      exclude_self = FALSE
    )

#### Arguments

- `query`:

  Query data of class data.frame

- `k`:

  number of similar cases

- `add_distance`:

  Add distance to result data.frame

- `merge`:

  Add query data to matched cases data.frame

- `exclude_self`:

  Exclude training cases whose row name equals the query's row name. Use
  this when the query rows are taken from the training data, so that a
  case is not returned as its own nearest neighbour.

------------------------------------------------------------------------

### Method `predict_survival()`

Predict survival curves from the `k` most similar training cases: a
Kaplan-Meier estimate over the retrieved cases of each query (Lowsky et
al., 2013). Only for survival endpoints (`Surv(time, status)`).

#### Usage

    CBRBase$predict_survival(query, k = 10, times = NULL, weighted = FALSE)

#### Arguments

- `query`:

  Query data of class data.frame

- `k`:

  number of similar cases

- `times`:

  time points; default: the event times of the training data

- `weighted`:

  If `TRUE`, cases are weighted with a tricube kernel of their distance
  to the query.

#### Returns

A matrix of survival probabilities with one row per query and one column
per time point (attribute `times`).

------------------------------------------------------------------------

### Method `evaluate_survival()`

Evaluate survival predictions from retrieved cases on test data: Uno's
concordance index and the IPCW (integrated) Brier score. Use it to
choose `k` and the distance method on held-out data.

#### Usage

    CBRBase$evaluate_survival(
      test,
      k = 10,
      times = NULL,
      tau = NULL,
      weighted = FALSE
    )

#### Arguments

- `test`:

  Test data with the endpoint columns

- `k`:

  number of similar cases

- `times`:

  time points for the Brier score; default: 20 points between the 10%
  and 90% quantile of the training event times

- `tau`:

  time horizon for the concordance index (risk score \\1 - S(\tau)\\);
  default: the largest of `times`

- `weighted`:

  passed to `predict_survival()`

#### Returns

A list with `c_index` (Uno's C), `ibs` (integrated Brier score) and
`brier` (data.frame with the Brier score at each time).

------------------------------------------------------------------------

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CBRBase$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
