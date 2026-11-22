# Get the terminal node id of a RandomForest Object

Extracts for each observation and for each tree in the forest the
terminal node id. The index of terminal nodes are starting with 1, e.g.,
the root node has id 1

## Usage

``` r
terminalNodes(x, rfObject)

terminal_nodes(x, rfObject)
```

## Arguments

- x:

  a data.frame

- rfObject:

  `ranger` object

## Value

Matrix with terminal node IDs for all observations in x (rows) and trees
(columns)

## Examples

``` r
library(ranger)
rf.fit <- ranger(Species ~ ., data = iris, num.trees = 5, write.forest = TRUE)
dfNodes <- terminal_nodes(iris[, -5], rf.fit)
```
