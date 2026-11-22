# Forest2Matrix

Transform trees of a `ranger`-object to a matrix

## Usage

``` r
ranger_forests_to_matrix(rfObject)
```

## Arguments

- rfObject:

  `ranger` object

## Value

a `matrix` object with Column 1: tree ID Column 2: node ID Column 3:
child node ID 1 Column 4: child node ID 2

## Examples

``` r
# \donttest{
library(ranger)
rf.fit <- ranger(Species ~ ., data = iris, num.trees = 5, write.forest = TRUE)
forest_matrix <- ranger_forests_to_matrix(rf.fit)
# }
```
