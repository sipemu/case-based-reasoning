# CBR Workflow: Step by Step

Each stage is a self-contained R snippet. Every method named here is a public method of
the package's model classes, or an exported function.

---

## Stage 1: Prepare the data

```r
library(CaseBasedReasoning)
library(survival)

df <- na.omit(lung[, c("time", "status", "age", "sex", "ph.ecog", "ph.karno", "wt.loss")])
df$status <- df$status - 1                       # status must be 0/1 or logical
df$sex <- factor(df$sex, labels = c("male", "female"))

set.seed(1)
idx <- sample(nrow(df), round(0.75 * nrow(df)))
train <- df[idx, ]
test <- df[-idx, ]
```

Rules:

- `fit()` drops incomplete training cases with a warning.
- Missing values in a query are an **error**: impute them or drop those rows first.
- Factor levels of a query are matched to the training levels by name. An unknown level
  is an error.
- Ordered factors keep their order, which the Gower distance uses.

---

## Stage 2: Choose candidate distances

Use `choosing-a-distance.md`. In most analyses, fit one regression model and one forest,
and use the Gower distance as a baseline.

---

## Stage 3: Fit and check

```r
cox <- CoxModel$new(Surv(time, status) ~ rcs(age, 3) + sex + ph.ecog + ph.karno + wt.loss, train)
cox$fit()
cox$check_ph()                  # proportional hazards (survival::cox.zph); needs patchwork

# optional: backward variable selection (rms::fastbw), then refit
cox$variable_selection()                      # shows the retained terms
# cox$variable_selection(update = TRUE); cox$fit()

set.seed(42)
rf <- RFModel$new(Surv(time, status) ~ age + sex + ph.ecog + ph.karno + wt.loss, train,
                  num.trees = 500)
rf$fit()                                      # default distance: Depth
# rf$set_distance_method("Proximity", proximity_type = "rfgap")

gower <- GowerModel$new(Surv(time, status) ~ age + sex + ph.ecog + ph.karno + wt.loss, train)
gower$fit()
```

- For numeric endpoints use `LinearModel`; for binary endpoints use `LogisticModel`.
- `RFModel` handles numeric, class and survival endpoints. Use the same formula style.

---

## Stage 4: Retrieve and explain

```r
query <- test[1, ]
sc <- cox$get_similar_cases(query, k = 5)       # adds columns scDist, caseId
sc
cox$get_similar_cases(query, k = 5, merge = TRUE)   # with the query row, group column

# why is the nearest case similar?
cox$explain_match(query, sc[1, ])

# in-sample (leave-one-out) retrieval
cox$get_similar_cases(train[1:3, ], k = 5, exclude_self = TRUE)

# full distance matrix (training x query) for clustering or heatmaps
D <- cox$calc_distance_matrix(test)
```

---

## Stage 5: Reuse

```r
# survival endpoints: Kaplan-Meier curve of the k nearest cases
cox$predict_survival(test[1:5, ], k = 20, times = c(182, 365, 730))

# class / numeric endpoints: vote with probabilities, or (weighted) mean
# m$predict_outcome(test, k = 10, weighted = TRUE)

# nearest cases with a different outcome (event status at the horizon)
cox$get_counterfactual_cases(query, k = 2, horizon = 365)
```

---

## Stage 6: Evaluate and compare

Choose `k` and the distance on held-out data:

```r
models <- list(Cox = cox, RF = rf, Gower = gower)
grid <- expand.grid(model = names(models), k = c(10, 20, 40), stringsAsFactors = FALSE)
grid$c_index <- NA
grid$ibs <- NA
for (i in seq_len(nrow(grid))) {
  ev <- models[[grid$model[i]]]$evaluate_survival(test, k = grid$k[i])
  grid$c_index[i] <- ev$c_index
  grid$ibs[i] <- ev$ibs
}
grid
```

- For class and numeric endpoints, use `$evaluate(test, k)`. It returns accuracy, Brier
  score and log loss, or RMSE and MAE.
- With small test sets, repeat over several splits or folds before you compare. The
  *Benchmark* article has a cross-validation helper (`run_cv`).

To see how much two distances agree, compare their neighbourhoods:

```r
nn <- function(m, k) apply(m$calc_distance_matrix(test), 2, order)[1:k, , drop = FALSE]
jaccard <- function(a, b) mean(sapply(seq_len(ncol(a)), function(q)
  length(intersect(a[, q], b[, q])) / length(union(a[, q], b[, q]))))
jaccard(nn(cox, 10), nn(rf, 10))
```

---

## Stage 7: Maintain the case base

```r
cox$add_cases(test[1:10, ])                    # no refit (refit = TRUE refits)
nrow(cox$get_case_base())

a <- cox$assess_cases(k = 10, horizon = 365)
table(a$category, a$noisy, useNA = "ifany")
cox$remove_cases(rownames(a)[which(a$noisy)])  # e.g. Wilson editing
```

For an `RFModel` with `proximity_type = "oob"` or `"rfgap"`, call `$fit()` after
adding or removing cases. Depth and original proximity keep working without a refit.
