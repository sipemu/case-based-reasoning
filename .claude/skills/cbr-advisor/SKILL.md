---
name: cbr-advisor
description: |
  Run and advise on a case-based reasoning analysis with the CaseBasedReasoning R
  package: prepare the data, choose and fit a distance (Cox/linear/logistic regression,
  random forest, Gower), check the model, retrieve and explain similar cases, predict
  outcomes or survival curves from the neighbours, choose k and compare distances on
  held-out data, and maintain the case base (noisy, pivotal, redundant cases). Use this
  skill whenever a user asks to find similar cases or patients, build a k-NN or CBR
  analysis in R, compare distances, interpret evaluate(), explain_match() or
  assess_cases() output, or decide which CaseBasedReasoning model fits their data.
---

# CaseBasedReasoning Advisor Skill

This skill runs a complete loop:
**prepare → choose distance → fit and check → retrieve and explain → reuse → evaluate
and compare → maintain**. It uses only methods exported by the package; for the API
inventory see the **cbr-capabilities** skill.

## Overview

| Stage | What happens | Key calls |
|-------|--------------|-----------|
| 1. Prepare | Complete cases, factors, train/test split | `na.omit()`, `factor()` |
| 2. Choose | Pick candidate distances for the endpoint and data | see `reference/choosing-a-distance.md` |
| 3. Fit and check | Fit, check the assumptions, select variables | `$fit()`, `$check_ph()`, `$variable_selection()` |
| 4. Retrieve | Similar cases and why they are similar | `$get_similar_cases()`, `$explain_match()` |
| 5. Reuse | Predictions and counterfactuals from the neighbours | `$predict_outcome()`, `$predict_survival()`, `$get_counterfactual_cases()` |
| 6. Evaluate and compare | Choose `k` and the distance on held-out data | `$evaluate()`, `$evaluate_survival()` |
| 7. Maintain | Add cases, find noisy and redundant cases | `$add_cases()`, `$assess_cases()`, `$remove_cases()` |

## Reference Files

- **`reference/workflow.md`**: concrete R code for each stage.
- **`reference/choosing-a-distance.md`**: a decision guide with the advantages and
  disadvantages of each distance.
- **`reference/interpreting-results.md`**: how to read the outputs of `explain_match()`,
  `evaluate()`, `evaluate_survival()` and `assess_cases()`, plus common pitfalls.

## Quick Entry Point (survival data)

```r
Rscript -e '
  library(CaseBasedReasoning); library(survival)
  df <- na.omit(lung[, c("time", "status", "age", "sex", "ph.ecog")])
  df$status <- df$status - 1
  df$sex <- factor(df$sex, labels = c("male", "female"))
  set.seed(1); idx <- sample(nrow(df), 0.75 * nrow(df))
  m <- CoxModel$new(Surv(time, status) ~ rcs(age, 3) + sex + ph.ecog, df[idx, ])
  m$fit()
  print(m$get_similar_cases(df[-idx, ][1, ], k = 5))
  print(m$explain_match(df[-idx, ][1, ], df[idx, ][1, ]))
  str(m$evaluate_survival(df[-idx, ], k = 20)[c("c_index", "ibs")])
'
```

## Ground Rules

- **Never report a number you did not compute.** Run the code and quote its output.
  Distances, C-indices and shares depend on the data, the split and the seed.
- **Compare distances on the same held-out data**, using the same `k` and the same
  seed. On small test sets, differences in C-index or accuracy of a few hundredths are
  usually noise. Say so instead of declaring a winner.
- **The distance inherits the model's assumptions.** For a `CoxModel`, run
  `check_ph()` before you trust its distance. For an `RFModel`, set a seed.
- **Look at the retrieved cases, not only the scores.** Distances that predict equally
  well can retrieve very different neighbours.
- Point users to the vignettes for the theory: *Methods* (mathematics, worked examples,
  advantages and disadvantages), *Comparing the Approaches* (all distances on one data
  set), and the *Benchmark* article.
  <https://sipemu.github.io/case-based-reasoning/articles/>
