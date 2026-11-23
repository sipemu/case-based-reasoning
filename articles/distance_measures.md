# Motivation

## Objective

#### Define a Distance Measure for Numerical and Categorical Features

Let $`x_i = \left(x_i^1,\cdots,x_i^p\right)^T`$ and
$`x_j = \left(x_j^1,\cdots,x_j^p\right)^T`$ be the feature vectors of
two distinct patients $`i`$ and $`j`$. A first rough idea may be to
calculate the $`L_1-`$norm of this two feature vectors:
``` math
\|x_i - x_j\|_{L_1}=\frac{1}{p}\sum\limits_{k=1}^p|x_i^k - x_j^k|
```

However, this naive approach arises from some problems:

1.  This measure is well-defined for numerical features but not for
    categorical features, such as gender (male/female). We need a method
    to define the distance for categorical variables.

2.  $`|x_i^k - x_j^k|`$ is not scale-invariant, meaning that if one
    changes the unit of measurement (e.g., from meters to centimeters),
    the contribution of this feature would increase by a factor of 100.
    Features with large values will dominate the distance.

3.  All features are treated equally, which may not reflect their actual
    importance. For example, in the case of lung cancer, the patient’s
    smoking status (no/yes) seems more relevant than the city they live
    in.

This package addresses these issues by deriving a weighted distance from
regression model coefficients, which naturally handles mixed feature
types and reflects each feature’s importance.

### Weighted Distance Measure

To address the challenges discussed earlier, we need to perform two
steps:

1.  Generalize the L1-distance to handle different variable types,
    including numerical and categorical features.

2.  Assign appropriate weights to each feature to:

    a\. eliminate the dependency on the scale of the variables,

    2.  account for varying importance across features, and
    3.  consider the impact size of each feature.

By incorporating these modifications, we arrive at the following
weighted distance measure:

``` math
d(x_i, x_j) = \sum\limits_{k=1}^p |\alpha(x_i^k, x_j^k) d(x_i^k, x_j^k)|
```

The weighted distance measure now includes weights
$`\alpha(x_i^k, x_j^k)`$, which are determined based on the training
data. In the next section, we will discuss how to obtain these weights
and effectively compute the weighted distance measure for mixed data
types and varying feature importance.

## Statistical Model

Let $`\alpha(x_i^k, x_j^k)`$ the weights and $`d(x_i^k, x_j^k)`$ the
distance for feature $`k`$ and observation $`i`$ and $`j`$. We will
define them as:

If feature $`k`$ is numerical, then

``` math
d(x_i^k, x_j^k) = x_i^k - x_j^k
```
and

``` math
\alpha(x_i^k, x_j^k) = \hat{\beta}_k
```

If feature $`k`$ is categorical, then

``` math
d(x_i^k, x_j^k) = 1 \text{ when } x_i^k \neq x_j^k \text{ else } 0
```
and
``` math
\alpha(x_i^k, x_j^k) = \hat{\beta}_k^{(x_i^k)} - \hat{\beta}_k^{(x_j^k)},
```

where $`\hat{\beta}_k^{(l)}`$ is the coefficient of level $`l`$ (zero
for the reference level) in a regression model (linear, logistic, or CPH
model). The regression coefficients thus serve as weights that reflect
each feature’s importance and scale.

### Contribution Space

Both cases are special cases of one definition. Let
$`c_t(x) = X_t(x)\hat{\beta}_t`$ be the contribution of model term $`t`$
to the linear predictor, where $`X_t(x)`$ are the columns of the design
matrix that belong to term $`t`$ and $`\hat{\beta}_t`$ their
coefficients. The package computes

``` math
d(x_i, x_j) = \sum\limits_{t} |c_t(x_i) - c_t(x_j)|.
```

For a numerical main effect, $`c_t(x) = \hat{\beta}_k x^k`$; for a
categorical one, $`c_t(x) = \hat{\beta}_k^{(x^k)}`$, so the distance is
exactly the weighted distance above. The definition also covers any
other term of an **rms** model: splines such as `rcs(age, 4)`,
polynomials and interactions. Two cases are then close if the model
assigns them similar contributions, even if a non-linear effect makes
equal differences in a variable count differently in different ranges.

`explain_match()` reports the terms $`|c_t(x_i) - c_t(x_j)|`$ and their
share of the distance, which shows why two cases match.

## Random Forests

### Proximity Measure

Two observations $`i`$ and $`j`$ are considered more similar when the
fraction of trees in which they share the same terminal node is close to
one (Breiman, 2002). With proximity

``` math
p(x_i, x_j) = \frac{1}{T}\sum\limits_{t=1}^T 1_{[x_i \text{ and } x_j \text{ share the same terminal node in tree } t]},
```

where $`T`$ is the number of trees, the distance is

``` math
d(x_i, x_j) = \sqrt{1 - p(x_i, x_j)}.
```

A drawback of this measure is that the decision is binary, meaning that
potentially similar observations might be counted as dissimilar. For
example, suppose a final cut-off is consistently made around age 58, and
observation 1 has an age of 56 while observation 2 has an age of 60. In
this case, the distance between observation 1 and observation 2 would be
the same as the distance between observation 1 and an observation with
an age of 80. This limitation makes the proximity measure less sensitive
to small differences between observations, potentially affecting the
overall analysis of similarity.

### Out-of-Bag and RF-GAP Proximities

The original proximity is biased for training cases: a tree is grown
until its leaves are small, so cases in a tree’s bootstrap sample tend
to share leaves with each other. Two variants avoid this
(`proximity_type` in
[`proximity_distance()`](https://sipemu.github.io/case-based-reasoning/reference/proximity_distance.md),
[`distance_random_forest()`](https://sipemu.github.io/case-based-reasoning/reference/distance_random_forest.md)
and `RFModel$set_distance_method()`):

- **OOB**: only the trees in which both observations are out-of-bag are
  counted, and $`T`$ is replaced by the number of these trees.

- **RF-GAP** (Rhodes, Cutler & Moon, 2023): for a query $`q`$ and a
  training case $`j`$,
  ``` math
  p(q, j) = \frac{1}{|S_q|}\sum\limits_{t \in S_q} \frac{c_j(t)\, 1_{[j \in v_q(t)]}}{|M_q(t)|},
  ```
  where $`S_q`$ are the trees in which $`q`$ is out-of-bag (all trees
  for new data), $`v_q(t)`$ is the terminal node of $`q`$ in tree $`t`$,
  $`c_j(t)`$ is the in-bag count of $`j`$ in tree $`t`$, and
  $`|M_q(t)|`$ is the total in-bag count in $`v_q(t)`$.

The RF-GAP proximities of a query sum to one over the training cases,
and the proximity-weighted average of the training outcomes equals the
forest’s (out-of-bag) prediction. Retrieval with RF-GAP therefore uses
the same notion of similarity as the forest’s predictions. Because the
proximities are small, RF-GAP distances lie close to 1; only their order
matters. Both variants need the in-bag counts, which `RFModel` keeps by
default (`keep.inbag = TRUE`).

### Depth Measure: A modified proximity measure

In contrast to the proximity measure, the depth measure takes into
account the number of edges between the terminal nodes of two
observations, not only whether they coincide. It is summed over all
trees:

``` math
d(x_i, x_j) = \sum\limits_{t=1}^T g_{ij}(t),
```

where $`g_{ij}(t)`$ is the number of edges on the path between the
terminal nodes of observation $`i`$ and $`j`$ in tree $`t`$, i.e. the
sum of their distances to the deepest common ancestor. Observations that
end up in neighbouring leaves are close, observations in distant parts
of the tree are far apart. This is the default distance of `RFModel`.

The edge counts are computed on demand from each tree’s structure, so
the cost grows with the number of pairs and the tree depth, not with the
number of nodes.

For more details and a thorough explanation of the depth measure, refer
to the publication by Englund and Verikas: “[A novel approach to
estimate proximity in a random forest: An exploratory
study.](https://doi.org/10.1016/j.eswa.2012.05.094)”

## References

- Breiman, L. (2002). Manual on setting up, using, and understanding
  random forests V3.1.
- Dippon, J. et al. (2002). [A statistical approach to case based
  reasoning, with application to breast cancer
  data](https://doi.org/10.1016/S0167-9473(02)00058-0).
- Englund, C. and Verikas, A. (2012). [A novel approach to estimate
  proximity in a random forest: An exploratory
  study](https://doi.org/10.1016/j.eswa.2012.05.094).
- Rhodes, J. S., Cutler, A. and Moon, K. R. (2023). [Geometry- and
  Accuracy-Preserving Random Forest
  Proximities](https://doi.org/10.1109/TPAMI.2023.3263774).
