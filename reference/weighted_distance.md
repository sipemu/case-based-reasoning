# Weighted Distance calculation

Computes \\d(x_i, y_j) = \sum_k \|w_k (x\_{ik} - y\_{jk})\|\\.

## Usage

``` r
weightedDistance(x, y = NULL, weights = NULL)

weighted_distance(x, y = NULL, weights = NULL)
```

## Arguments

- x:

  a numeric matrix

- y:

  a second numeric matrix with the same columns as `x` (default: `NULL`,
  pairwise distances within `x`)

- weights:

  a vector of weights, one per column (default: all 1)

## Value

a `dist` object (if `y` is `NULL`) or a `nrow(x)` x `nrow(y)` matrix

## Examples

``` r
x <- as.matrix(iris[1:5, 1:4])
weighted_distance(x)
#>     1   2   3   4
#> 2 0.7            
#> 3 0.8 0.5        
#> 4 1.0 0.5 0.4    
#> 5 0.2 0.7 0.8 1.0
weighted_distance(x, as.matrix(iris[6:7, 1:4]), weights = c(1, 1, 2, 2))
#>      [,1] [,2]
#> [1,]  1.7  0.8
#> [2,]  2.4  0.9
#> [3,]  2.6  0.7
#> [4,]  2.4  0.7
#> [5,]  1.7  0.8
```
