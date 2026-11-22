# Counterfactual cases and match explanations (#23)

test_that("counterfactuals for a classification endpoint have a different class", {
  df <- iris
  df$virginica <- as.integer(df$Species == "virginica")
  m <- LogisticModel$new(virginica ~ Sepal.Length + Sepal.Width, df)
  m$fit()
  q <- df[c(101, 120, 1), ]
  cf <- m$get_counterfactual_cases(q, k = 3)
  expect_equal(nrow(cf), 9)
  expect_equal(cf$queryOutcome, rep(as.character(q$virginica), each = 3))
  expect_true(all(as.character(cf$virginica) != cf$queryOutcome))

  # nearest among the counterfactuals
  d <- m$calc_distance_matrix(q[1, ])
  other <- which(df$virginica != q$virginica[1])
  expect_equal(cf$scDist[1], min(d[other, 1]))

  # without the endpoint, the outcome is predicted from similar cases
  cf2 <- m$get_counterfactual_cases(q[, c("Sepal.Length", "Sepal.Width")], k = 2, k_outcome = 15)
  expect_equal(nrow(cf2), 6)
  expect_true(all(as.character(cf2$virginica) != cf2$queryOutcome))
})

test_that("counterfactuals for numeric and survival endpoints", {
  m <- LinearModel$new(Sepal.Length ~ Petal.Length + Petal.Width, iris)
  m$fit()
  cf <- m$get_counterfactual_cases(iris[c(1, 51), ], k = 2, min_diff = 1)
  expect_true(all(abs(cf$Sepal.Length - cf$queryOutcome) >= 1))

  ov <- survival::ovarian
  ov$rx <- factor(ov$rx)
  cm <- CoxModel$new(survival::Surv(futime, fustat) ~ age + rx, ov)
  cm$fit()
  cf_s <- cm$get_counterfactual_cases(ov[1:3, ], k = 2, horizon = 500)
  lab <- ifelse(cf_s$futime <= 500 & cf_s$fustat == 1, "event", "no event")
  expect_true(all(cf_s$futime > 500 | cf_s$fustat == 1))
  expect_true(all(lab != cf_s$queryOutcome))
  expect_error(cm$get_counterfactual_cases(ov[1, ], k = 100), "larger than|counterfactual case")
})

test_that("explain_match() decomposes the regression distance", {
  ov <- survival::ovarian
  ov$rx <- factor(ov$rx)
  ov$ecog.ps <- factor(ov$ecog.ps)
  m <- CoxModel$new(survival::Surv(futime, fustat) ~ rcs(age, 3) + rx + ecog.ps, ov)
  m$fit()
  ex <- m$explain_match(ov[1, ], ov[5, ])
  expect_setequal(ex$term, m$terms)
  expect_equal(sum(ex$distance), m$calc_distance_matrix(ov[1, ])[5, 1])
  expect_equal(sum(ex$share), 1)
  expect_true(all(diff(ex$distance) <= 0))
  expect_error(m$explain_match(ov[1:2, ], ov[5, ]), "exactly one row")
})

test_that("explain_match() for random forests counts diverging split variables", {
  set.seed(9)
  m <- RFModel$new(Species ~ ., iris, num.trees = 40)
  m$fit()
  ex <- m$explain_match(iris[1, ], iris[60, ])
  expect_equal(nrow(ex), 4)
  tn <- terminal_nodes(iris[c(1, 60), -5], m$model_fit)
  n_diff <- sum(tn[1, ] != tn[2, ])
  expect_equal(sum(ex$n_trees), n_diff)
  expect_equal(attr(ex, "same_leaf"), mean(tn[1, ] == tn[2, ]))
  # setosa vs versicolor are separated by petal variables
  expect_true(ex$variable[1] %in% c("Petal.Length", "Petal.Width"))
})
