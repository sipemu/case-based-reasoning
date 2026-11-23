# Package index

## Models

- [`CoxModel`](https://sipemu.github.io/case-based-reasoning/reference/CoxModel.md)
  : Cox-Beta Model for Case-Based-Reasoning
- [`LinearModel`](https://sipemu.github.io/case-based-reasoning/reference/LinearModel.md)
  : Linear Regression Model for Case-Based-Reasoning
- [`LogisticModel`](https://sipemu.github.io/case-based-reasoning/reference/LogisticModel.md)
  : Logistic Regression Model for Case-Based-Reasoning
- [`RFModel`](https://sipemu.github.io/case-based-reasoning/reference/RFModel.md)
  : RandomForest Model for Searching Similar Cases

## S3 methods

- [`predict(`*`<CoxModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/predict.CoxModel.md)
  : Predict method for CoxModel
- [`predict(`*`<LinearModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/predict.LinearModel.md)
  : Predict method for LinearModel
- [`predict(`*`<LogisticModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/predict.LogisticModel.md)
  : Predict method for LogisticModel
- [`predict(`*`<RFModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/predict.RFModel.md)
  : Predict method for RFModel
- [`print(`*`<CoxModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/print.CoxModel.md)
  : Print method for CoxModel
- [`print(`*`<LinearModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/print.LinearModel.md)
  : Print method for LinearModel
- [`print(`*`<LogisticModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/print.LogisticModel.md)
  : Print method for LogisticModel
- [`print(`*`<RFModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/print.RFModel.md)
  : Print method for RFModel
- [`summary(`*`<CoxModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/summary.CoxModel.md)
  : Summary method for CoxModel
- [`summary(`*`<LinearModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/summary.LinearModel.md)
  : Summary method for LinearModel
- [`summary(`*`<LogisticModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/summary.LogisticModel.md)
  : Summary method for LogisticModel
- [`summary(`*`<RFModel>`*`)`](https://sipemu.github.io/case-based-reasoning/reference/summary.RFModel.md)
  : Summary method for RFModel

## Distances

- [`distanceRandomForest()`](https://sipemu.github.io/case-based-reasoning/reference/distance_random_forest.md)
  [`distance_random_forest()`](https://sipemu.github.io/case-based-reasoning/reference/distance_random_forest.md)
  : Distance calculation based on RandomForest Proximity or Depth
- [`proximity_distance()`](https://sipemu.github.io/case-based-reasoning/reference/proximity_distance.md)
  : Get proximity matrix of an ranger object
- [`depth_distance()`](https://sipemu.github.io/case-based-reasoning/reference/depth_distance.md)
  : Depth Distance
- [`weightedDistance()`](https://sipemu.github.io/case-based-reasoning/reference/weighted_distance.md)
  [`weighted_distance()`](https://sipemu.github.io/case-based-reasoning/reference/weighted_distance.md)
  : Weighted Distance calculation

## Random forest internals

- [`terminalNodes()`](https://sipemu.github.io/case-based-reasoning/reference/terminal_nodes.md)
  [`terminal_nodes()`](https://sipemu.github.io/case-based-reasoning/reference/terminal_nodes.md)
  : Get the terminal node id of a RandomForest Object
- [`ranger_forests_to_matrix()`](https://sipemu.github.io/case-based-reasoning/reference/ranger_forests_to_matrix.md)
  : Forest2Matrix
- [`edges_between_terminal_nodes()`](https://sipemu.github.io/case-based-reasoning/reference/edges_between_terminal_nodes.md)
  : Number of Edges between Terminal Nodes

## Utilities

- [`generate_grid()`](https://sipemu.github.io/case-based-reasoning/reference/generate_grid.md)
  : Generate Grid

- [`asDistObject()`](https://sipemu.github.io/case-based-reasoning/reference/as_dist_object.md)
  [`as_dist_object()`](https://sipemu.github.io/case-based-reasoning/reference/as_dist_object.md)
  :

  Converts a distance vector into an object of class `dist`

## Base classes

- [`CBRBase`](https://sipemu.github.io/case-based-reasoning/reference/CBRBase.md)
  : Root class for common functionality of this package
- [`RegressionModel`](https://sipemu.github.io/case-based-reasoning/reference/RegressionModel.md)
  : Root class for Regression Models, e.g., CPH, logistic, and linear
  regression

## Package

- [`CaseBasedReasoning`](https://sipemu.github.io/case-based-reasoning/reference/CaseBasedReasoning-package.md)
  [`CaseBasedReasoning-package`](https://sipemu.github.io/case-based-reasoning/reference/CaseBasedReasoning-package.md)
  : CaseBasedReasoning: Case Based Reasoning
