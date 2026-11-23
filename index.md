# Case Based Reasoning using Statistical Models

The R package CaseBasedReasoning implements case-based reasoning with
statistical and machine learning models: it learns a distance between
cases from a fitted regression model or random forest, retrieves the
most similar past cases, predicts outcomes (including survival curves)
from them, and explains why cases match.

## Introduction: What is Case Based Reasoning?

Case-Based Reasoning (CBR) is an artificial intelligence (AI) and
problem-solving methodology that leverages the knowledge and experience
gained from previously encountered situations, known as cases, to
address new and complex problems. CBR relies on the principle that
similar problems often have similar solutions, and it focuses on
identifying, adapting, and reusing those solutions to solve new
problems.

The CBR process consists of four main steps:

- **Retrieve**: In this step, the system searches its case database to
  identify the most similar cases to the current problem. It uses
  similarity measures and pattern matching techniques to compare the
  features of the new problem with the existing cases.

- **Reuse**: Once the relevant cases are retrieved, the system adapts
  the solutions from those cases to fit the new problem. This may
  involve combining multiple solutions, adjusting parameters, or
  modifying the solution to accommodate any differences between the old
  and new cases.

- **Revise**: After the adapted solution has been applied to the new
  problem, the system evaluates the outcome to determine its
  effectiveness. If necessary, the solution is further revised and
  optimized to better suit the specific context of the problem.

- **Retain**: Finally, the new problem and its corresponding solution
  are added to the case database for future reference. This step
  enhances the system’s knowledge base and improves its ability to solve
  similar problems in the future.

CBR has been successfully applied in various domains, including medical
diagnosis, legal reasoning, customer support, and design optimization.
Its ability to learn from experience and adapt to new situations makes
it a valuable approach in fields where expertise and problem-solving
skills are crucial.

## How This Package Implements CBR

The central challenge in CBR is defining what “similar” means. This
package solves the **Retrieve** step by learning a distance function
from data rather than relying on ad-hoc similarity measures.

The workflow follows three stages:

1.  **Fit a statistical model** to the training data. The model captures
    which variables matter and how strongly they influence the outcome.
2.  **Derive a distance function** from the fitted model. The model’s
    structure determines how distance between cases is measured.
3.  **Retrieve the k nearest cases** for each new query observation
    using the learned distance.

The package offers two families of models for this:

### Regression-based distance (Cox, linear, logistic)

A regression model (Cox proportional hazards, OLS, or logistic
regression via the [rms](https://CRAN.R-project.org/package=rms)
package) is fitted on the training data. The estimated regression
coefficients are then used as **weights** in a weighted absolute
distance function. Variables with larger coefficients contribute more to
the distance, while variables the model deems irrelevant contribute
little. This follows the approach of Dippon et al. (2002).

Distances are computed in *contribution space*: for each model term t,
the contribution to the linear predictor, `c_t(x) = X_t(x) %*% beta_t`,
is compared between two cases, and the absolute differences are summed.
For main effects this is exactly the weighted distance above; it also
covers any other rms term, such as splines (`rcs(age, 4)`), polynomials
and interactions.

### Random Forest distance (proximity and depth)

A random forest (via the [ranger](https://github.com/imbs-hl/ranger)
package) is fitted on the training data. Two distance measures can be
extracted:

- **Proximity distance**: Two observations are similar if they
  frequently land in the same terminal node across trees; the distance
  is `sqrt(1 - proximity)`. Besides Breiman’s original proximity, the
  out-of-bag (OOB) proximity and RF-GAP (Rhodes, Cutler & Moon, 2023)
  are available. RF-GAP removes the in-bag bias of the original measure:
  the RF-GAP weighted average of the training outcomes reproduces the
  forest’s prediction.
- **Depth distance** (default): The distance between two observations is
  the sum of edges between their terminal nodes across all trees in the
  forest, following Englund and Verikas (2012). Unlike proximity, it
  distinguishes cases that end up in neighbouring leaves from cases in
  distant parts of the tree.

Both approaches produce an (n x m) distance matrix, where n is the
number of training observations and m the number of query observations.
This matrix can be used directly for clustering or visualization, or
passed to the built-in k-nearest-neighbor search to retrieve the most
similar cases.

## Documentation

- [Get
  Started](https://sipemu.github.io/case-based-reasoning/articles/get_started.html):
  a hands-on tour through the CBR cycle.
- [Methods](https://sipemu.github.io/case-based-reasoning/articles/distance_measures.html):
  the mathematics of each distance and step, with worked examples and
  advantages and disadvantages.
- [Comparing the
  Approaches](https://sipemu.github.io/case-based-reasoning/articles/comparing_approaches.html):
  all distances applied to the same data: retrieved cases, feature
  weights, predictions, irrelevant features and stability.
- [Benchmark](https://sipemu.github.io/case-based-reasoning/articles/benchmark.html):
  predictive performance against the Gower distance and a learned metric
  (NCA).

## Installation

#### CRAN

``` R
install.packages("CaseBasedReasoning")
```

#### GITHUB

``` R
install.packages("devtools")
devtools::install_github("sipemu/case-based-reasoning")
```

## Features

- **Models**: linear, logistic and Cox regression (with splines and
  interactions), and random forests
  ([ranger](https://github.com/imbs-hl/ranger)) for numeric, binary,
  multi-class and survival endpoints; `GowerModel` as a model-free
  baseline.
- **Distances**: regression-weighted (contribution-space) distance;
  random forest proximity (original, OOB, RF-GAP) and depth distance,
  implemented in parallel C++; the Gower distance for mixed data.
- **Outcome prediction**: `predict_outcome()` predicts classes (with
  probabilities) and numeric outcomes from the nearest cases;
  `evaluate()` scores them (accuracy, Brier score, log loss; RMSE, MAE).
- **Retrieval**: `get_similar_cases()` /
  [`predict()`](https://rdrr.io/r/stats/predict.html) return the k
  nearest training cases per query, optionally merged with the query and
  excluding the query itself (`exclude_self = TRUE`).
- **Survival prediction**: `predict_survival()` estimates a Kaplan–Meier
  curve from each query’s nearest cases; `evaluate_survival()` scores it
  with Uno’s C-index and the integrated Brier score.
- **Counterfactuals**: `get_counterfactual_cases()` returns the most
  similar cases with a *different* outcome.
- **Explanations**: `explain_match()` shows which variables make two
  cases similar or different.
- **Retain and maintenance**: `add_cases()` and `remove_cases()` change
  the case base without refitting; `assess_cases()` finds noisy, pivotal
  and redundant cases (Wilson editing; Smyth & Keane, 1995).
- **Checks**: query data are validated against the training data (factor
  levels are matched by name, unknown levels and missing values are
  errors), and `check_ph()` checks the proportional hazards assumption
  of the Cox model.

## Missing Values

Training cases with missing values in the endpoint or the predictors are
dropped when the model is fitted, with a warning that lists them. They
are excluded consistently from fitting, distance calculation and
retrieval. Missing values in a query are an error, so impute them or
remove those cases first.

## Example: Cox Beta Model

### Initialization

In the first example, we use the CPH model and the `ovarian` data set
from the `survival` package. In the first step, we initialize the R6
data object.

``` R
library(survival)
library(CaseBasedReasoning)
ovarian$resid.ds <- factor(ovarian$resid.ds)
ovarian$rx <- factor(ovarian$rx)
ovarian$ecog.ps <- factor(ovarian$ecog.ps)

# initialize R6 object
cph_model <- CoxModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps, data = ovarian)
```

### Similar Cases

After the initialization, we may want to get for each case in the query
data the most similar case from the learning data.

``` r

n <- nrow(ovarian)
trainID <- sample(1:n, floor(0.8 * n), FALSE)
testID <- (1:n)[-trainID]
cph_model <- CoxModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps, data = ovarian[trainID, ])

# fit model
cph_model$fit()

# get similar cases
matched_tbl <- cph_model$get_similar_cases(query = ovarian[testID, ], k = 3)

# or use the standard S3 predict interface
matched_tbl <- predict(cph_model, newdata = ovarian[testID, ], k = 3)
```

To analyze the results, you can extract the similar cases and training
data and combine them:

- **Note 1**: Training cases with missing values are dropped when the
  model is fitted (see [Missing Values](#missing-values)).

- **Note 2**: The data.frame returned from
  `cph_model$get_similar_cases()` contains the matched training cases, k
  rows per query, with additional columns:

  - **scDist**: The distance between the query and the matched case.

  - **caseId**: Rank of the match for its query (1 = most similar, …,
    k).

  With `merge = TRUE`, the query cases are included as well, and two
  more columns identify them:

  - **scCaseId**: Number of the query case; a query and its matches
    share the same value.

  - **group**: `"Query"` or `"Matched"`.

### Distance Matrix

The distance matrix is a square matrix that represents the pairwise
distances between a set of data points. In the context of Case-Based
Reasoning (CBR), the distance matrix captures the dissimilarities
between cases in the training and test (or query) datasets, based on the
fitted model and the values of the predictor variables.

The distance matrix can be helpful in various situations:

- **Identifying Similar Cases**: By examining the distance matrix, you
  can identify the most similar cases to a given query case. Smaller
  distances indicate higher similarity, enabling the retrieval of
  relevant cases for CBR.

- **Clustering and Grouping**: The distance matrix can be used as input
  for clustering algorithms, such as hierarchical clustering or k-means
  clustering, to group cases with similar characteristics. This can
  provide insights into the structure and patterns within the data.

- **Visualizing Relationships**: By creating a heatmap of the distance
  matrix, you can visualize the relationships between cases. This
  representation can help identify trends and anomalies in the data,
  guiding further analysis and decision-making.

- **Model Validation**: The distance matrix can be used to assess the
  performance of the CPH regression model or other statistical models
  employed in the CBR process. Comparing the distance matrix for
  different models can help determine which model better captures the
  relationships between cases.

In summary, a distance matrix can provide valuable insights into the
relationships between cases, facilitate the identification of similar
cases for CBR, and aid in the validation of the chosen statistical
models.

``` r

distance_matrix <- cph_model$calc_distance_matrix()
```

`cph_model$calc_distance_matrix()` calculates the distance matrix
between train and test data. When test data is omitted, the distances
between observations in the training data are calculated. Rows are
observations in train and columns observations of test. The distance
matrix is saved internally in the `CoxModel` object:
`cph_model$dist_matrix`.

## Beyond Retrieval

### Survival prediction

For survival endpoints, the retrieved cases yield a prediction: a
Kaplan–Meier estimate over each query’s k nearest training cases (Lowsky
et al., 2013). `evaluate_survival()` scores the predictions on held-out
data with Uno’s C-index and the integrated Brier score, so `k` and the
distance method can be tuned. The `ovarian` test set above is too small
for that, so we use `lung`:

``` r

lung_df <- na.omit(lung[, c("time", "status", "age", "sex", "ph.ecog", "wt.loss")])
lung_df$status <- lung_df$status - 1
lung_df$sex <- factor(lung_df$sex)
train <- sample(nrow(lung_df), 150)

lung_model <- CoxModel$new(Surv(time, status) ~ rcs(age, 3) + sex + ph.ecog + wt.loss,
                           lung_df[train, ])
lung_model$fit()

# survival probabilities at 1 and 2 years: one row per query
lung_model$predict_survival(lung_df[-train, ], k = 30, times = c(365, 730))

# Uno's C-index and integrated Brier score on test data
lung_model$evaluate_survival(lung_df[-train, ], k = 30)
```

### Counterfactual cases and explanations

`get_counterfactual_cases()` returns the most similar training cases
whose outcome differs from the query’s (Keane & Smyth, 2020). For
survival endpoints, the outcome is the event status at `horizon`.
`explain_match()` breaks a distance down: per model term for regression
models, and per split variable at which the tree paths diverge for
random forests.

``` r

query <- ovarian[testID[1], ]
cph_model$get_counterfactual_cases(query, k = 2, horizon = 365)

match <- cph_model$get_similar_cases(query, k = 1)
cph_model$explain_match(query, match)
```

### Outcome prediction

For class and numeric endpoints, `predict_outcome()` predicts from the k
nearest cases: a majority vote with class probabilities, or a mean.
`evaluate()` scores the predictions on test data, and
`predict(model, newdata, type = "outcome")` is the S3 shortcut.

``` r

rf_model <- RFModel$new(Species ~ ., data = iris[-(1:5), ])
rf_model$fit()
rf_model$predict_outcome(iris[1:5, ], k = 10)
rf_model$evaluate(iris[1:5, ], k = 10)
```

### Retaining and maintaining cases

New solved cases can be added to the case base without refitting the
model, and `assess_cases()` retrieves each case against the others to
find noisy cases (most neighbours have a different outcome), pivotal
cases (no other case solves them) and redundant cases:

``` r

cph_model$add_cases(ovarian[testID, ])
assessment <- cph_model$assess_cases(k = 3, horizon = 365)
cph_model$remove_cases(rownames(assessment)[which(assessment$noisy)])
```

### Model-free baseline

`GowerModel` uses the Gower distance for mixed data with optional
weights and supports the same methods. It is a baseline for the
model-derived distances; the [benchmark
article](https://sipemu.github.io/case-based-reasoning/articles/benchmark.html)
compares the distances with each other and with a learned metric (NCA).

``` r

gower_model <- GowerModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps, ovarian[trainID, ])
gower_model$fit()
gower_model$get_similar_cases(ovarian[testID, ], k = 3)
```

## Example: Random Forest

``` r

rf_model <- RFModel$new(Species ~ ., data = iris, num.trees = 500)
rf_model$fit()

# default: depth distance
rf_model$get_similar_cases(iris[c(1, 51, 101), ], k = 3)

# RF-GAP proximity
rf_model$set_distance_method("Proximity", proximity_type = "rfgap")
rf_model$get_similar_cases(iris[c(1, 51, 101), ], k = 3)

# which variables separate two flowers in the forest?
rf_model$explain_match(iris[51, ], iris[60, ])
```

RF-GAP proximities are normalised to sum to one over the training cases,
so RF-GAP distances lie close to 1; only their order matters for
retrieval.

## Contribution

### Responsible for Mathematical Model Development and Programming

- [PD Dr. Jürgen
  Dippon](https://www.isa.uni-stuttgart.de/institut/team/Dippon/),
  Institut für Stochastik und Anwendungen, Universität Stuttgart

- [Dr. Simon Müller](https://data-zoo.de/), DataZoo GmbH

### Medical Advisor

- Dr. Peter Fritz

- Professor Dr. Friedel

### Funding

The Robert Bosch Foundation funded this work. Special thanks go to
Professor Dr. Friedel (Thoraxchirugie - Klinik Schillerhöhe).

## References

### Main

- Dippon et al. [A statistical approach to case based reasoning, with
  application to breast cancer
  data](https://doi.org/10.1016/S0167-9473(02)00058-0) (2002),

- Friedel et al. [Postoperative Survival of Lung Cancer Patients: Are
  There Predictors beyond
  TNM?](https://ar.iiarjournals.org/content/33/4/1609.short) (2012).

### Other

- Rhodes, Cutler and Moon [Geometry- and Accuracy-Preserving Random
  Forest Proximities](https://doi.org/10.1109/TPAMI.2023.3263774) (2023)

- Lowsky et al. [A K-nearest neighbors survival probability prediction
  method](https://doi.org/10.1002/sim.5673) (2013)

- Keane and Smyth [Good Counterfactuals and Where to Find Them: A
  Case-Based Technique for Generating Counterfactuals for Explainable
  AI](https://doi.org/10.1007/978-3-030-58342-2_11) (2020)

- Gower [A general coefficient of similarity and some of its
  properties](https://doi.org/10.2307/2528823) (1971)

- Smyth and Keane, Remembering to forget: A competence-preserving case
  deletion policy for case-based reasoning systems, IJCAI-95 (1995)

- Englund and Verikas [A novel approach to estimate proximity in a
  random forest: An exploratory
  study](https://doi.org/10.1016/j.eswa.2012.05.094)

- Stuart, E. et al. [Matching methods for causal inference: Designing
  observational studies](https://doi.org/10.4135/9781412995627.d14)

- Defossez et al. [Temporal representation of care trajectories of
  cancer patients using data from a regional information system: an
  application in breast cancer](https://doi.org/10.1186/1472-6947-14-24)
