[![cran version](http://www.r-pkg.org/badges/version/CaseBasedReasoning)](https://cran.rstudio.com/web/packages/CaseBasedReasoning) [![rstudio mirror downloads](http://cranlogs.r-pkg.org/badges/CaseBasedReasoning?)](https://cran.r-project.org/web/packages/CaseBasedReasoning/)

# Case Based Reasoning using Statistical Models

The R package case-based-reasoning provides an R interface case-based reasoning using machine learning methods.

## Introduction: What is Case Based Reasoning? {#introduction}

Case-Based Reasoning (CBR) is an artificial intelligence (AI) and problem-solving methodology that leverages the knowledge and experience gained from previously encountered situations, known as cases, to address new and complex problems. CBR relies on the principle that similar problems often have similar solutions, and it focuses on identifying, adapting, and reusing those solutions to solve new problems.

The CBR process consists of four main steps:

-   **Retrieve**: In this step, the system searches its case database to identify the most similar cases to the current problem. It uses similarity measures and pattern matching techniques to compare the features of the new problem with the existing cases.

-   **Reuse**: Once the relevant cases are retrieved, the system adapts the solutions from those cases to fit the new problem. This may involve combining multiple solutions, adjusting parameters, or modifying the solution to accommodate any differences between the old and new cases.

-   **Revise**: After the adapted solution has been applied to the new problem, the system evaluates the outcome to determine its effectiveness. If necessary, the solution is further revised and optimized to better suit the specific context of the problem.

-   **Retain**: Finally, the new problem and its corresponding solution are added to the case database for future reference. This step enhances the system's knowledge base and improves its ability to solve similar problems in the future.

CBR has been successfully applied in various domains, including medical diagnosis, legal reasoning, customer support, and design optimization. Its ability to learn from experience and adapt to new situations makes it a valuable approach in fields where expertise and problem-solving skills are crucial.

In the context of observational studies, Case-Based Reasoning (CBR) can be integrated with statistical models to enhance the process of searching for similar cases, especially when dealing with large and complex datasets. By applying statistical techniques, the system can identify patterns, relationships, and associations among variables that are relevant to the problem at hand. This approach can lead to more accurate and efficient retrieval of relevant cases, ultimately improving the quality of the derived solutions (See our Vignettes).

## Installation {#installation}

#### CRAN {#cran}

    install.packages("CaseBasedReasoning")

#### GITHUB {#github}

    install.packages("devtools")
    devtools::install_github("sipemu/case-based-reasoning")

## Features {#features}

This R package provides two methods case-based reasoning by using an endpoint:

-   Linear, logistic, and CPH Regression

-   Proximity and Depth Measure extracted from a fitted random forest ([ranger](https://github.com/imbs-hl/ranger) package)

Besides the functionality of searching for similar cases, we added some additional features:

-   automatic validation of the critical variables between the query and similar cases dataset

-   checking proportional hazard assumption for the Cox Model

-   C++-functions for distance calculation

## Example: Cox Beta Model {#example-cox-beta-model}

### Initialization {#initialization}

In the first example, we use the CPH model and the `ovarian` data set from the `survival` package. In the first step, we initialize the R6 data object.

    library(tidyverse)
    library(survival)
    library(CaseBasedReasoning)
    ovarian$resid.ds <- factor(ovarian$resid.ds)
    ovarian$rx <- factor(ovarian$rx)
    ovarian$ecog.ps <- factor(ovarian$ecog.ps)

    # initialize R6 object
    coxBeta <- CoxBetaModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps)

### Similar Cases {#similar-cases}

After the initialization, we may want to get for each case in the query data the most similar case from the learning data.

```{r}
n <- nrow(ovarian)
trainID <- sample(1:n, floor(0.8 * n), F)
testID <- (1:n)[-trainID]

# fit model 
ovarian[trainID, ] %>% 
  coxBeta$fit()
# get similar cases
ovarian[testID, ] %>%
  coxBeta$get_similar_cases(queryData = ovarian[testID, ], k = 3) -> matchedData
```

You may extract then the similar cases and the verum data and put them together:

**Note 1:** In the initialization step, we dropped all cases with missing values in the variables of `data` and `endPoint`. So, you need to make sure that you do missing value analysis before.

**Note 2:** The `data.table` returned from `coxBeta$get_similar_cases` has four additional columns:

1.  `caseId`: By this column, you may map the similar cases to cases in data, e.g., if you had chosen `k = 3`, then the first three elements in the column `caseId` will be `1` (following three `2` and so on). These three cases are the three most similar cases to case `0` in verum data.
2.  `scDist`: The calculated distance
3.  `scCaseId`: Grouping number of the query with matched data
4.  `group`: Grouping matched or query data

### Distance Matrix {#distance-matrix}

Alternatively, you may be interested in the distance matrix:

```{r}
ovarian %>%
  coxBeta$calc_distance_matrix() -> distMatrix
```

`coxBeta$calc_distance_matrix()` calculates the distance matrix between train and test data, when test data is omitted, the distances between observations in the test data is calculated. Rows are observations in train and columns observations of test. The distance matrix is saved internally in the `CoxBetaModel` object: `coxBeta$distMat`.

## Example: RandomForest Model {#example-randomforest-model}

### Initialization {#initialization-1}

In the second example, we apply a RandomForest model for approximating the distance measure on the `ovarian` data. Two possibilities for distance/similarity calculation are offered (details can be found in the documentation):

-   Proximity: When comparing two observations, the mean of having the same end node over all trees is calculated

-   Depth: When comparing two observations, the mean length of edges between the two end nodes over all trees is calculated

Let's initialize the model object:

```{r, warning=FALSE, message=FALSE}
library(tidyverse)
library(survival)
library(CaseBasedReasoning)
ovarian$resid.ds <- factor(ovarian$resid.ds)
ovarian$rx <- factor(ovarian$rx)
ovarian$ecog.ps <- factor(ovarian$ecog.ps)

# initialize R6 object
rfSC <- RFModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps)
```

All observations with missing values in training and endpoint variables are dropped (`na.omit`) and the reduced data without missing values is stored internally. You get a text output on how many cases were dropped. Furthermore, `character` variables will be transformed to `factor`.

Optionally, you can adjust RandomForest parameters when initializing the model. The documentation of set able parameters can be found in the ranger R-package.

As described, we offer two distance measures are offered:

-   `Depth` (Default)
-   `Proximity`

```{r, warning=FALSE, message=FALSE}
rfSC$set_dist(distMethod = "Proximity")
```

All following steps are the same as above:

**Similar Cases:**

```{r}
n <- nrow(ovarian)
trainID <- sample(1:n, floor(0.8 * n), F)
testID <- (1:n)[-trainID]

# train model 
ovarian[trainID, ] %>% 
  rfSC$fit()
# get similar cases
ovarian[trainID, ] %>%
  rfSC$get_similar_cases(queryData = ovarian[testID, ], k = 3) -> matchedData
```

**Distance Matrix Calculation:**

```{r}
ovarian %>%
  rfSC$calc_distance_matrix() -> distMatrix
```

## Contribution {#contribution}

### Responsible for Mathematical Model Development and Programming {#responsible-for-mathematical-model-development-and-programming}

-   [PD Dr. Jürgen Dippon](http://www.isa.uni-stuttgart.de/LstStoch/Dippon/), Institut für Stochastik und Anwendungen, Universität Stuttgart

-   [Dr. Simon Müller](http://muon-stat.com/), TTI GmbH - MUON-STAT

### Medical Advisor {#medical-advisor}

-   Dr. Peter Fritz

-   Professor Dr. Friedel

### Funding {#funding}

The Robert Bosch Foundation funded this work. Special thanks go to Professor Dr. Friedel ([Thoraxchirugie - Klinik Schillerhöhe](http://www.rbk.de/standorte/klinik-schillerhoehe/abteilungen/thoraxchirurgie/team.html)).

## References {#references}

### Main {#main}

-   Dippon et al. [A statistical approach to case based reasoning, with application to breast cancer data](http://dl.acm.org/citation.cfm?id=608456) (2002),

-   Friedel et al. [Postoperative Survival of Lung Cancer Patients: Are There Predictors beyond TNM?](http://ar.iiarjournals.org/content/33/4/1609.short) (2012).

### Other {#other}

-   Englund and Verikas [A novel approach to estimate proximity in a random forest: An exploratory study](https://www.researchgate.net/publication/257404436_A_novel_approach_to_estimate_proximity_in_a_random_forest_An_exploratory_study)

-   Stuart, E. et al. [Matching methods for causal inference: Designing observational studies](http://www.biostat.jhsph.edu/~estuart/StuRub_MatchingChapter_07.pdf)

-   Defossez et al. [Temporal representation of care trajectories of cancer patients using data from a regional information system: an application in breast cancer](http://www.biomedcentral.com/1472-6947/14/24)
