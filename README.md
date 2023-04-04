[![cran version](http://www.r-pkg.org/badges/version/CaseBasedReasoning)](https://CRAN.R-project.org/package=CaseBasedReasoning) [![rstudio mirror downloads](http://cranlogs.r-pkg.org/badges/CaseBasedReasoning?)](https://CRAN.R-project.org/package=CaseBasedReasoning/)

# Case Based Reasoning using Statistical Models

The R package case-based-reasoning provides an R interface case-based reasoning using machine learning methods.

## Introduction: What is Case Based Reasoning?

Case-Based Reasoning (CBR) is an artificial intelligence (AI) and problem-solving methodology that leverages the knowledge and experience gained from previously encountered situations, known as cases, to address new and complex problems. CBR relies on the principle that similar problems often have similar solutions, and it focuses on identifying, adapting, and reusing those solutions to solve new problems.

The CBR process consists of four main steps:

-   **Retrieve**: In this step, the system searches its case database to identify the most similar cases to the current problem. It uses similarity measures and pattern matching techniques to compare the features of the new problem with the existing cases.

-   **Reuse**: Once the relevant cases are retrieved, the system adapts the solutions from those cases to fit the new problem. This may involve combining multiple solutions, adjusting parameters, or modifying the solution to accommodate any differences between the old and new cases.

-   **Revise**: After the adapted solution has been applied to the new problem, the system evaluates the outcome to determine its effectiveness. If necessary, the solution is further revised and optimized to better suit the specific context of the problem.

-   **Retain**: Finally, the new problem and its corresponding solution are added to the case database for future reference. This step enhances the system's knowledge base and improves its ability to solve similar problems in the future.

CBR has been successfully applied in various domains, including medical diagnosis, legal reasoning, customer support, and design optimization. Its ability to learn from experience and adapt to new situations makes it a valuable approach in fields where expertise and problem-solving skills are crucial.

In the context of observational studies, Case-Based Reasoning (CBR) can be integrated with statistical models to enhance the process of searching for similar cases, especially when dealing with large and complex datasets. By applying statistical techniques, the system can identify patterns, relationships, and associations among variables that are relevant to the problem at hand. This approach can lead to more accurate and efficient retrieval of relevant cases, ultimately improving the quality of the derived solutions (See our Vignettes).

## Installation

#### CRAN

    install.packages("CaseBasedReasoning")

#### GITHUB

    install.packages("devtools")
    devtools::install_github("sipemu/case-based-reasoning")

## Features

This R package provides two methods case-based reasoning by using an endpoint:

-   Linear, logistic, and CPH Regression

-   Proximity and Depth Measure extracted from a fitted random forest ([ranger](https://github.com/imbs-hl/ranger) package)

Besides the functionality of searching for similar cases, we added some additional features:

-   Automatic validation of the critical variables between the query and similar cases dataset

-   Checking proportional hazard assumption for the Cox Model

-   C++-functions for distance calculation

## Warning Message

"Warning: Cases with missing values in the dependent variable (Y) or predictor variables (X) have been dropped from the analysis. This may lead to a reduced dataset and potential loss of information. Please review your data and consider appropriate missing value imputation techniques to mitigate these issues."

Potential Solutions:

-   **Missing Value Analysis**: Conduct a thorough missing value analysis to understand the nature and extent of the missing data. Determine if the data is missing at random (MAR), missing completely at random (MCAR), or missing not at random (MNAR). This information will guide the choice of imputation methods.

-   **Imputation Techniques:** Depending on the nature of the missing data, various imputation techniques can be applied to fill in the gaps:

    a.  **Mean/Median/Mode Imputation**: Replace missing values with the mean, median, or mode of the variable. This method is simple but can distort the distribution of the data.

    b.  **Regression Imputation**: Use linear regression models to predict missing values based on the relationships between the predictor variables. This technique assumes that the relationships between variables are linear.

    c.  **k-Nearest Neighbors Imputation (k-NN)**: Fill in missing values using the values from the k most similar cases in the dataset. The similarity is determined using distance metrics such as Euclidean or Manhattan distance.

    d.  **Multiple Imputation**: Generate multiple imputed datasets by creating a range of plausible values for each missing value. Analyze each imputed dataset separately and then pool the results to obtain a final estimate.

-   **Sensitivity Analysis**: After applying an imputation method, perform a sensitivity analysis to assess the impact of the imputed values on the overall results. This will help evaluate the robustness of the findings and the potential biases introduced by the imputation.

By addressing missing values appropriately, you can mitigate the risk of losing valuable information and improve the quality of the analysis.

## Example: Cox Beta Model

### Initialization

In the first example, we use the CPH model and the `ovarian` data set from the `survival` package. In the first step, we initialize the R6 data object.

    library(tidyverse)
    library(survival)
    library(CaseBasedReasoning)
    ovarian$resid.ds = factor(ovarian$resid.ds)
    ovarian$rx = factor(ovarian$rx)
    ovarian$ecog.ps = factor(ovarian$ecog.ps)

    # initialize R6 object
    cph_model = CoxModel$new(Surv(futime, fustat) ~ age + resid.ds + rx + ecog.ps)

### Similar Cases

After the initialization, we may want to get for each case in the query data the most similar case from the learning data.

```{r}
n <- nrow(ovarian)
trainID = sample(1:n, floor(0.8 * n), F)
testID = (1:n)[-trainID]

# fit model 
cph_model$fit()

# get similar cases
matched_tbl = cph_model$get_similar_cases(queryData = ovarian[testID, ], k = 3)
```

To analyze the results, you can extract the similar cases and training data and combine them:

-   **Note 1**: During the initialization step, all cases with missing values in the data and endPoint variables were removed. Be sure to conduct a missing value analysis beforehand.

-   **Note 2**: The data.table returned from coxBeta\$get_similar_cases contains four columns that help identify the query cases, their matches, and the distances between them:

    -   **caseId**: This column allows you to map the similar cases to cases in the data. For example, if you chose k = 3, the first three elements in the caseId column will be 1 (followed by three 2s, and so on). These three cases are the three most similar cases to case 0 in the verum data.

    -   **scDist**: The calculated distance between the cases.

    -   **scCaseId**: Grouping number of the query case with its matched data.

    -   **group**: Grouping indicator for matched or query data.

These columns help organize and interpret the results, ensuring a clear understanding of the most similar cases and their corresponding query cases.

### Distance Matrix

The distance matrix is a square matrix that represents the pairwise distances between a set of data points. In the context of Case-Based Reasoning (CBR), the distance matrix captures the dissimilarities between cases in the training and test (or query) datasets, based on the fitted model and the values of the predictor variables.

The distance matrix can be helpful in various situations:

-   **Identifying Similar Cases**: By examining the distance matrix, you can identify the most similar cases to a given query case. Smaller distances indicate higher similarity, enabling the retrieval of relevant cases for CBR.

-   **Clustering and Grouping**: The distance matrix can be used as input for clustering algorithms, such as hierarchical clustering or k-means clustering, to group cases with similar characteristics. This can provide insights into the structure and patterns within the data.

-   **Visualizing Relationships**: By creating a heatmap of the distance matrix, you can visualize the relationships between cases. This representation can help identify trends and anomalies in the data, guiding further analysis and decision-making.

-   **Model Validation**: The distance matrix can be used to assess the performance of the CPH regression model or other statistical models employed in the CBR process. Comparing the distance matrix for different models can help determine which model better captures the relationships between cases.

In summary, a distance matrix can provide valuable insights into the relationships between cases, facilitate the identification of similar cases for CBR, and aid in the validation of the chosen statistical models.

```{r}
ditance_matrix = cph_model$fit$calc_distance_matrix()
```

`cph_model$calc_distance_matrix()` calculates the distance matrix between train and test data, when test data is omitted, the distances between observations in the test data is calculated. Rows are observations in train and columns observations of test. The distance matrix is saved internally in the `CoxModel` object: `cph_model$distMat`.


## Contribution

### Responsible for Mathematical Model Development and Programming

-   [PD Dr. Jürgen Dippon](http://www.isa.uni-stuttgart.de/LstStoch/Dippon/), Institut für Stochastik und Anwendungen, Universität Stuttgart

-   [Dr. Simon Müller](http://muon-stat.com/), TTI GmbH - MUON-STAT

### Medical Advisor

-   Dr. Peter Fritz

-   Professor Dr. Friedel

### Funding

The Robert Bosch Foundation funded this work. Special thanks go to Professor Dr. Friedel (Thoraxchirugie - Klinik Schillerhöhe).

## References

### Main

-   Dippon et al. [A statistical approach to case based reasoning, with application to breast cancer data](https://dl.acm.org/citation.cfm?id=608456) (2002),

-   Friedel et al. [Postoperative Survival of Lung Cancer Patients: Are There Predictors beyond TNM?](https://ar.iiarjournals.org/content/33/4/1609.short) (2012).

### Other {#other}

-   Englund and Verikas [A novel approach to estimate proximity in a random forest: An exploratory study](https://www.researchgate.net/publication/257404436_A_novel_approach_to_estimate_proximity_in_a_random_forest_An_exploratory_study)

-   Stuart, E. et al. [Matching methods for causal inference: Designing observational studies](https://www.biostat.jhsph.edu/~estuart/StuRub_MatchingChapter_07.pdf)

-   Defossez et al. [Temporal representation of care trajectories of cancer patients using data from a regional information system: an application in breast cancer](https://www.biomedcentral.com/1472-6947/14/24)
