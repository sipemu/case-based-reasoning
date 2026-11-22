# Root class for common functionality of this package

Root class for common functionality of this package

Root class for common functionality of this package

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

  terms of the formula

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

### Method `clone()`

The objects of this class are cloneable with this method.

#### Usage

    CBRBase$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
