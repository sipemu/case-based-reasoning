# Generate Grid

Generates a uniform grid over the distribution of the time2event
variable, calculates closest point and returns this point for each input
time2event element. Memory consumption will increase when performing the
randomForest model with many unique time2event values. Therefore, we
offer a reduction of the time2event values by choosing closest elements
in a grid.

## Usage

``` r
generate_grid(t2e, grid_length = 250)
```

## Arguments

- t2e:

  numeric vector with time2event values

- grid_length:

  number of grid elements

## Value

a list with new_t2e and grid_error
