# Get Started

## Motivation

Case-Based Reasoning (CBR) solves new problems by finding similar past
cases. This package uses regression models—Cox Proportional Hazards
(CPH), linear, and logistic—and random forests to define a principled
distance between cases. The workflow is: prepare data, fit a model, then
query for similar cases. The retrieved cases can then be used to predict
survival, to find counterfactual cases and to explain matches.

## Cox Proportional Hazard Model

We demonstrate the CPH model using the `ovarian` dataset from the
**survival** package.

``` r

ovarian$resid.ds <- factor(ovarian$resid.ds)
ovarian$rx <- factor(ovarian$rx)
ovarian$ecog.ps <- factor(ovarian$ecog.ps)

# initialize R6 object
cph_model <- CoxModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps, ovarian)
```

When the model is fitted, training cases with missing values are dropped
(with a warning) and character variables are converted to factors.
Factor levels of later queries are matched to the training data by name.

## Available Models

The package provides four model classes for estimating case similarity:

### **Linear Regression**

- Simple, fast, and interpretable via coefficients.
- Limited to continuous dependent variables.
- All regression models accept any rms term, e.g. splines
  (`rcs(age, 4)`) and interactions.

### **Logistic Regression**

- Suited for binary outcomes (e.g., success/failure).
- Assumes a linear relationship on the logit scale.

### **Cox Proportional Hazards Regression**

- Designed for time-to-event (survival) data with right-censoring.
- Assumes constant hazard ratios over time.

### **Random Forests**

- Captures non-linear relationships and feature interactions.
- More computationally expensive and less interpretable than regression
  models.

## Case Based Reasoning

### Search for Similar Cases

We split the data into training and query sets, then retrieve the most
similar training cases for each query case.

``` r

set.seed(42)
n <- nrow(ovarian)
trainID <- sample(1:n, floor(0.8 * n), FALSE)
testID <- (1:n)[-trainID]

cph_model <- CoxModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps, ovarian[trainID, ])

# fit model 
cph_model$fit()

# get similar cases
matched_data_tbl <- cph_model$get_similar_cases(query = ovarian[testID, ], k = 3)
knitr::kable(head(matched_data_tbl))
```

|     | futime | fustat |     age | resid.ds | rx  | ecog.ps |    scDist | caseId |
|:----|-------:|-------:|--------:|:---------|:----|:--------|----------:|-------:|
| 10  |    563 |      1 | 55.1781 | 1        | 2   | 2       | 0.7533753 |      1 |
| 7   |    464 |      1 | 56.9370 | 2        | 2   | 2       | 1.1760552 |      2 |
| 24  |    353 |      1 | 63.2192 | 1        | 2   | 2       | 1.4624169 |      3 |
| 71  |    464 |      1 | 56.9370 | 2        | 2   | 2       | 0.3736327 |      1 |
| 241 |    353 |      1 | 63.2192 | 1        | 2   | 2       | 0.9489132 |      2 |
| 14  |    770 |      0 | 57.0521 | 2        | 2   | 1       | 1.0646258 |      3 |

**Note 1:** Training cases with missing values are dropped when the
model is fitted, and missing values in a query are an error. Perform a
missing value analysis beforehand.

**Note 2:** The data.frame returned from
**`cph_model$get_similar_cases`** contains k matched training cases per
query, with two additional columns:

1.  `scDist`: The distance between the query and the matched case.
2.  `caseId`: Rank of the match for its query (1 = most similar).

With `merge = TRUE`, the query cases are included too, identified by two
more columns:

3.  `scCaseId`: Number of the query case; a query and its matches share
    the same value.
4.  `group`: `"Query"` or `"Matched"`.

``` r

merged_tbl <- cph_model$get_similar_cases(query = ovarian[testID[1:2], ], k = 2, merge = TRUE)
knitr::kable(merged_tbl)
```

|     | futime | fustat |     age | resid.ds | rx  | ecog.ps |    scDist | caseId | scCaseId | group   |
|:----|-------:|-------:|--------:|:---------|:----|:--------|----------:|-------:|---------:|:--------|
| 6   |    448 |      0 | 56.4301 | 1        | 1   | 2       | 0.0000000 |      0 |        1 | Query   |
| 10  |    563 |      1 | 55.1781 | 1        | 2   | 2       | 0.7533753 |      1 |        1 | Matched |
| 7   |    464 |      1 | 56.9370 | 2        | 2   | 2       | 1.1760552 |      2 |        1 | Matched |
| 8   |    475 |      1 | 59.8548 | 2        | 2   | 2       | 0.0000000 |      0 |        2 | Query   |
| 71  |    464 |      1 | 56.9370 | 2        | 2   | 2       | 0.3736327 |      1 |        2 | Matched |
| 24  |    353 |      1 | 63.2192 | 1        | 2   | 2       | 0.9489132 |      2 |        2 | Matched |

For in-sample queries, `exclude_self = TRUE` keeps a training case from
being returned as its own nearest neighbour.

### Check Proportional Hazard Assumption

Verify that the proportional hazards assumption holds for the fitted
model:

``` r

cph_model$check_ph()
```

![](get_started_files/figure-html/proportional%20hazard-1.png)

## Distance Matrix Calculation

You can also compute and visualize the full distance matrix:

``` r

distance_matrix <- cph_model$calc_distance_matrix()
heatmap(distance_matrix)
```

![](get_started_files/figure-html/distance_matrix-1.png)

**`cph_model$calc_distance_matrix()`** computes the distance matrix
between the train and test data. If test data is omitted, it calculates
distances within the training data. Rows correspond to training
observations and columns to test observations. The result is also stored
internally as **`cph_model$dist_matrix`**.

## Survival Prediction

The retrieved cases can also predict the outcome of a query. For
survival endpoints, `predict_survival()` estimates a Kaplan–Meier curve
from each query’s `k` nearest training cases (Lowsky et al., 2013). We
use the larger `lung` data set and model age with a restricted cubic
spline.

``` r

lung_df <- na.omit(lung[, c("time", "status", "age", "sex", "ph.ecog", "wt.loss")])
lung_df$status <- lung_df$status - 1
lung_df$sex <- factor(lung_df$sex, labels = c("male", "female"))

set.seed(1)
train <- sample(nrow(lung_df), 150)
lung_train <- lung_df[train, ]
lung_test <- lung_df[-train, ]

lung_model <- CoxModel$new(Surv(time, status) ~ rcs(age, 3) + sex + ph.ecog + wt.loss, lung_train)
lung_model$fit()

# survival probabilities after 6 months, 1 and 2 years
surv <- lung_model$predict_survival(lung_test[1:5, ], k = 30, times = c(182, 365, 730))
knitr::kable(surv, digits = 2)
```

|  182 |  365 |  730 |
|-----:|-----:|-----:|
| 0.57 | 0.45 | 0.06 |
| 0.83 | 0.50 | 0.16 |
| 0.56 | 0.33 | 0.07 |
| 0.79 | 0.45 | 0.16 |
| 0.57 | 0.44 | 0.06 |

`evaluate_survival()` scores these predictions on held-out data with
Uno’s C-index (higher is better) and the integrated Brier score (IBS,
lower is better). This is a natural way to choose `k`:

``` r

scores <- sapply(c(10, 30, 60), function(k) {
  ev <- lung_model$evaluate_survival(lung_test, k = k)
  c(k = k, c_index = ev$c_index, ibs = ev$ibs)
})
knitr::kable(t(scores), digits = 3)
```

|   k | c_index |   ibs |
|----:|--------:|------:|
|  10 |   0.645 | 0.193 |
|  30 |   0.603 | 0.191 |
|  60 |   0.631 | 0.184 |

With `weighted = TRUE`, closer cases get larger weights (tricube
kernel).

## Counterfactual Cases and Explanations

A similar case with a *different* outcome shows what distinguishes the
query from cases that fared otherwise (Keane & Smyth, 2020). For
survival endpoints, the outcome is the event status at `horizon`; if the
query’s outcome is unknown, it is predicted from its most similar cases.

``` r

query <- lung_test[1, ]
cf <- lung_model$get_counterfactual_cases(query, k = 2, horizon = 365)
knitr::kable(cf, digits = 3)
```

|     | time | status | age | sex  | ph.ecog | wt.loss | scDist | caseId | queryOutcome |
|:----|-----:|-------:|----:|:-----|--------:|--------:|-------:|-------:|:-------------|
| 55  |  689 |      1 |  59 | male |       1 |      15 |  0.044 |      1 | event        |
| 48  |  519 |      1 |  63 | male |       1 |      10 |  0.054 |      2 | event        |

`explain_match()` breaks the distance between two cases down by model
term: each term’s contribution to the linear predictor for both cases,
the absolute difference, and its share of the total distance.

``` r

knitr::kable(lung_model$explain_match(query, cf[1, ]), digits = 3)
```

| term        | query_contribution | case_contribution | distance | share |
|:------------|-------------------:|------------------:|---------:|------:|
| wt.loss     |             -0.113 |            -0.154 |    0.041 | 0.936 |
| rcs(age, 3) |             -0.463 |            -0.460 |    0.003 | 0.064 |
| sex         |              0.000 |             0.000 |    0.000 | 0.000 |
| ph.ecog     |              0.479 |             0.479 |    0.000 | 0.000 |

## Random Forests

`RFModel` derives the distance from a random forest fitted with
**ranger**. The default is the depth distance (number of edges between
the cases’ terminal nodes, summed over trees); `set_distance_method()`
switches to the proximity distance, optionally with out-of-bag or RF-GAP
proximities (Rhodes, Cutler & Moon, 2023).

``` r

set.seed(1)
rf_model <- RFModel$new(Species ~ ., data = iris, num.trees = 200)
rf_model$fit()
knitr::kable(rf_model$get_similar_cases(iris[c(1, 51, 101), ], k = 2), digits = 3)
```

|     | Sepal.Length | Sepal.Width | Petal.Length | Petal.Width | Species    | scDist | caseId |
|:----|-------------:|------------:|-------------:|------------:|:-----------|-------:|-------:|
| 1   |          5.1 |         3.5 |          1.4 |         0.2 | setosa     |  0.000 |      1 |
| 3   |          4.7 |         3.2 |          1.3 |         0.2 | setosa     |  0.000 |      2 |
| 51  |          7.0 |         3.2 |          4.7 |         1.4 | versicolor |  0.000 |      1 |
| 66  |          6.7 |         3.1 |          4.4 |         1.4 | versicolor |  0.215 |      2 |
| 101 |          6.3 |         3.3 |          6.0 |         2.5 | virginica  |  0.000 |      1 |
| 137 |          6.3 |         3.4 |          5.6 |         2.4 | virginica  |  0.000 |      2 |

``` r

rf_model$set_distance_method("Proximity", proximity_type = "rfgap")
knitr::kable(rf_model$get_similar_cases(iris[c(1, 51, 101), ], k = 2), digits = 3)
```

|     | Sepal.Length | Sepal.Width | Petal.Length | Petal.Width | Species    | scDist | caseId |
|:----|-------------:|------------:|-------------:|------------:|:-----------|-------:|-------:|
| 3   |          4.7 |         3.2 |          1.3 |         0.2 | setosa     |  0.988 |      1 |
| 5   |          5.0 |         3.6 |          1.4 |         0.2 | setosa     |  0.989 |      2 |
| 51  |          7.0 |         3.2 |          4.7 |         1.4 | versicolor |  0.977 |      1 |
| 87  |          6.7 |         3.1 |          4.7 |         1.5 | versicolor |  0.980 |      2 |
| 145 |          6.7 |         3.3 |          5.7 |         2.5 | virginica  |  0.983 |      1 |
| 101 |          6.3 |         3.3 |          6.0 |         2.5 | virginica  |  0.985 |      2 |

RF-GAP proximities sum to one over the training cases, so RF-GAP
distances lie close to 1; only their order matters for retrieval.

For forests, `explain_match()` lists the split variables at which the
two cases’ paths diverge, counted over trees:

``` r

knitr::kable(rf_model$explain_match(iris[51, ], iris[60, ]), digits = 3)
```

| variable     | n_trees | share |
|:-------------|--------:|------:|
| Sepal.Length |      69 | 0.885 |
| Petal.Length |       5 | 0.064 |
| Sepal.Width  |       4 | 0.051 |
| Petal.Width  |       0 | 0.000 |
