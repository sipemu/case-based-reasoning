# BoostModel: gradient boosting with a SHAP distance

lung_data <- function() {
  lung2 <- na.omit(survival::lung[, c("time", "status", "age", "sex", "ph.ecog", "wt.loss")])
  lung2$status <- lung2$status - 1
  lung2$sex <- factor(lung2$sex, labels = c("male", "female"))
  lung2
}

test_that("SHAP values add up to the margin and bound the distance", {
  skip_if_not_installed("xgboost")
  df <- lung_data()
  m <- BoostModel$new(survival::Surv(time, status) ~ age + sex + ph.ecog + wt.loss, df,
                      nrounds = 30)
  m$fit()
  phi <- m$shap_values(df[1:20, ])
  expect_equal(colnames(phi), c("age", "sex", "ph.ecog", "wt.loss"))
  X <- CaseBasedReasoning:::boost_design(df[1:20, ], m$variables)
  margin <- predict(m$model_fit, X, outputmargin = TRUE)
  expect_equal(rowSums(phi) + attr(phi, "bias"), margin, tolerance = 1e-4)

  # distance = L1 distance of the SHAP vectors, >= difference of the margins
  d <- m$calc_distance_matrix(df[1:20, ])
  train_phi <- m$shap_values(df)
  expect_equal(d[5, 3], sum(abs(train_phi[5, ] - phi[3, ])), tolerance = 1e-5)
  lp_train <- predict(m$model_fit, CaseBasedReasoning:::boost_design(df, m$variables),
                      outputmargin = TRUE)
  expect_true(all(d + 1e-4 >= abs(outer(lp_train, margin, "-"))))
  expect_equal(unname(diag(d[1:20, ])), rep(0, 20), tolerance = 1e-6)
})

test_that("a linear booster gives the coefficient-weighted distance", {
  skip_if_not_installed("xgboost")
  df <- iris[, 1:4]
  m <- BoostModel$new(Sepal.Length ~ Sepal.Width + Petal.Length + Petal.Width, df,
                      nrounds = 200,
                      params = list(booster = "gblinear", eta = 0.5, lambda = 0, alpha = 0))
  m$fit()
  w <- xgboost::xgb.importance(model = m$model_fit)
  beta <- setNames(w$Weight, w$Feature)[m$variables]
  ref <- abs(beta[1]) * abs(outer(df$Sepal.Width, df$Sepal.Width[1:3], "-")) +
         abs(beta[2]) * abs(outer(df$Petal.Length, df$Petal.Length[1:3], "-")) +
         abs(beta[3]) * abs(outer(df$Petal.Width, df$Petal.Width[1:3], "-"))
  expect_equal(unname(m$calc_distance_matrix(df[1:3, ])), unname(ref), tolerance = 1e-4)
})

test_that("factor dummies are summed per variable", {
  skip_if_not_installed("xgboost")
  df <- lung_data()
  df$ecog <- factor(df$ph.ecog)
  m <- BoostModel$new(survival::Surv(time, status) ~ age + ecog, df, nrounds = 20)
  m$fit()
  X <- CaseBasedReasoning:::boost_design(df[1:5, ], m$variables)
  expect_equal(colnames(X)[-1], paste0("ecog", levels(df$ecog)))
  raw <- predict(m$model_fit, X, predcontrib = TRUE)
  phi <- m$shap_values(df[1:5, ])
  expect_equal(unname(phi[, "ecog"]), unname(rowSums(raw[, 1 + seq_len(nlevels(df$ecog))])),
               tolerance = 1e-6)
})

test_that("classification: binary and multi-class objectives", {
  skip_if_not_installed("xgboost")
  set.seed(1)
  idx <- sample(nrow(iris), 100)
  m <- BoostModel$new(Species ~ ., iris[idx, ], nrounds = 30)
  m$fit()
  expect_equal(ncol(m$shap_values(iris[1:2, ])), 4 * 3)
  ev <- m$evaluate(iris[-idx, ], k = 5)
  expect_gt(ev$accuracy, 0.85)
  e <- m$explain_match(iris[1, ], iris[51, ])
  expect_equal(sum(e$share), 1)
  expect_true(all(grepl("\\[(setosa|versicolor|virginica)\\]$", e$term)))

  b <- BoostModel$new(case ~ age + parity + induced + spontaneous, infert, nrounds = 20)
  b$fit()
  expect_equal(ncol(b$shap_values(infert[1:2, ])), 4)
  expect_equal(levels(b$predict_outcome(infert[1:3, ], k = 10)$prediction), c("0", "1"))
})

test_that("survival prediction, explanation and retain work", {
  skip_if_not_installed("xgboost")
  df <- lung_data()
  m <- BoostModel$new(survival::Surv(time, status) ~ age + sex + ph.ecog + wt.loss,
                      df[1:150, ], nrounds = 30)
  m$fit()
  ev <- m$evaluate_survival(df[151:nrow(df), ], k = 20)
  expect_true(ev$c_index > 0.4 && ev$c_index < 1)
  e <- m$explain_match(df[151, ], df[1, ])
  expect_named(e, c("term", "query_contribution", "case_contribution", "distance", "share"))
  expect_equal(sum(e$distance), m$calc_distance_matrix(df[151, ])[1, 1], tolerance = 1e-5)

  m$add_cases(df[151:160, ])
  expect_equal(nrow(m$get_case_base()), 160)
  expect_equal(nrow(m$get_similar_cases(df[161, ], k = 3)), 3)
  expect_error(m$get_similar_cases(transform(df[161, ], sex = "other")), "Unknown level")
})

test_that("input checks", {
  skip_if_not_installed("xgboost")
  expect_error(BoostModel$new(~ age, lung_data()), "needs an endpoint")
  expect_error(BoostModel$new(time ~ age, lung_data(), nrounds = 0), "nrounds")
  m <- BoostModel$new(time ~ age, lung_data())
  expect_error(m$get_similar_cases(lung_data()[1, ]), "call \\$fit\\(\\)")
})
