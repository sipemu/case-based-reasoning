# Survival prediction from retrieved cases and evaluation (#21)

test_that("weighted Kaplan-Meier matches survival::survfit", {
  set.seed(1)
  time <- rexp(40)
  status <- rbinom(40, 1, 0.7)
  w <- runif(40)
  times <- c(0, 0.1, 0.5, 1, 2, 5)
  fit <- survival::survfit(survival::Surv(time, status) ~ 1, weights = w)
  ref <- summary(fit, times = times, extend = TRUE)$surv
  expect_equal(CaseBasedReasoning:::km_at(time, status, w, times), ref)
})

test_that("Brier score without censoring is the mean squared error", {
  set.seed(2)
  time <- rexp(30)
  status <- rep(1, 30)
  surv <- matrix(runif(30 * 3), 30)
  times <- c(0.2, 0.5, 1)
  bs <- CaseBasedReasoning:::brier_ipcw(surv, time, status, times, time, status)
  ref <- vapply(1:3, function(j) mean(((time > times[j]) - surv[, j])^2), numeric(1))
  expect_equal(bs, ref)
})

test_that("predict_survival() is the KM of the k nearest cases", {
  ov <- survival::ovarian
  ov$rx <- factor(ov$rx)
  m <- CoxModel$new(survival::Surv(futime, fustat) ~ age + rx, ov)
  m$fit()
  times <- c(100, 365, 730)
  s <- m$predict_survival(ov[1:3, ], k = 8, times = times)
  expect_equal(dim(s), c(3, 3))
  expect_equal(attr(s, "times"), times)
  expect_true(all(s >= 0 & s <= 1))
  expect_true(all(apply(s, 1, function(r) all(diff(r) <= 0))))

  nn <- m$get_similar_cases(ov[2, ], k = 8)
  fit <- survival::survfit(survival::Surv(futime, fustat) ~ 1, data = nn)
  expect_equal(unname(s[2, ]), summary(fit, times = times, extend = TRUE)$surv)

  sw <- m$predict_survival(ov[1:3, ], k = 8, times = times, weighted = TRUE)
  expect_equal(dim(sw), c(3, 3))
  expect_error(LinearModel$new(Sepal.Length ~ Sepal.Width, iris)$predict_survival(iris[1, ]),
               "survival endpoint")
})

test_that("evaluate_survival() returns C-index and integrated Brier score", {
  lung <- survival::lung
  lung$status <- lung$status - 1
  lung <- lung[stats::complete.cases(lung[, c("time", "status", "age", "sex", "ph.ecog")]), ]
  set.seed(3)
  idx <- sample(nrow(lung), 150)
  train <- lung[idx, ]
  test <- lung[-idx, ]
  m <- CoxModel$new(survival::Surv(time, status) ~ age + sex + ph.ecog, train)
  m$fit()
  ev <- m$evaluate_survival(test, k = 20)
  expect_named(ev, c("c_index", "ibs", "brier"))
  expect_true(ev$c_index > 0.5 && ev$c_index < 1)
  expect_true(ev$ibs > 0 && ev$ibs < 0.25)
  expect_equal(ncol(ev$brier), 2)

  # also works for random survival forests
  set.seed(4)
  rf <- RFModel$new(survival::Surv(time, status) ~ age + sex + ph.ecog, train, num.trees = 50)
  rf$fit()
  rf$set_distance_method("Proximity")
  ev_rf <- rf$evaluate_survival(test, k = 20)
  expect_true(ev_rf$c_index > 0.4)
})
