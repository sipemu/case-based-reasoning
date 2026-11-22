# Retain: adding and removing cases (#45)

test_that("added cases are retrievable without refitting", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length + Species, iris[1:140, ])
  m$fit()
  coef_before <- coef(m$model_fit)
  new <- iris[141:150, ]
  m$add_cases(new)
  expect_equal(coef(m$model_fit), coef_before)
  expect_equal(nrow(m$get_case_base()), 150)
  # rows 125 and 145 are identical in the model variables
  sc <- m$get_similar_cases(iris[145, ], k = 2)
  expect_equal(sc$scDist, c(0, 0))
  expect_true("145" %in% rownames(sc))

  # distances among the original cases are unchanged
  ref <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length + Species, iris[1:140, ])
  ref$fit()
  expect_equal(m$calc_distance_matrix(iris[1:3, ])[1:140, ], ref$calc_distance_matrix(iris[1:3, ]))
})

test_that("refit = TRUE refits on the extended case base", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length, iris[1:100, ])
  m$fit()
  m$add_cases(iris[101:150, ], refit = TRUE)
  full <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length, iris)
  full$fit()
  expect_equal(coef(m$model_fit), coef(full$model_fit))
})

test_that("new cases are validated", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Species, iris[1:100, ])
  m$fit()
  expect_error(m$add_cases(iris[101, c("Sepal.Width", "Species")]), "Endpoint column")
  na_ep <- iris[60, ]
  na_ep$Sepal.Length <- NA
  expect_error(m$add_cases(na_ep), "Missing values in the endpoint")
  # virginica is not a level of the fitted model
  expect_error(m$add_cases(iris[101, ]), "Unknown level")
  m$add_cases(iris[101:110, ], refit = TRUE)
  sc <- m$get_similar_cases(iris[105, ], k = 1)
  expect_equal(as.character(sc$Species), "virginica")
})

test_that("removed cases are no longer retrieved", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length, iris)
  m$fit()
  d_before <- m$calc_distance_matrix(iris[1:2, ])
  m$remove_cases(c("1", "2"))
  expect_equal(nrow(m$get_case_base()), 148)
  sc <- m$get_similar_cases(iris[1:2, ], k = 1)
  expect_false(any(rownames(sc) %in% c("1", "2")))
  expect_equal(m$calc_distance_matrix(iris[1:2, ]), d_before[-(1:2), ], ignore_attr = TRUE)

  m$remove_cases(1:3)
  expect_equal(rownames(m$get_case_base())[1], "6")
  expect_error(m$remove_cases("999"), "Unknown case")
  expect_error(m$remove_cases(0), "positions")
  expect_error(m$remove_cases(seq_len(nrow(m$get_case_base()))), "all cases")
})

test_that("incomplete rows are kept out after adding and removing", {
  df <- iris
  df$Sepal.Width[3] <- NA
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width, df)
  suppressWarnings(m$fit())
  m$remove_cases("1")
  m$add_cases(iris[150, ])
  cb <- m$get_case_base()
  expect_equal(nrow(cb), 149)
  expect_false(any(c("1", "3") %in% rownames(cb)))
  expect_false(anyNA(cb$Sepal.Width))
})

test_that("random forests: OOB/RF-GAP need a refit after changing the case base", {
  set.seed(1)
  rf <- RFModel$new(Species ~ ., iris[1:140, ], num.trees = 30)
  rf$fit()
  rf$add_cases(iris[141:150, ])
  expect_equal(nrow(rf$get_similar_cases(iris[145, ], k = 2)), 2)
  rf$set_distance_method("Proximity", proximity_type = "rfgap")
  expect_error(rf$get_similar_cases(iris[1, ], k = 1), "Refit")
  rf$set_distance_method("Proximity", proximity_type = "original")
  expect_equal(nrow(rf$get_similar_cases(iris[1, ], k = 1)), 1)
  rf$fit()
  rf$set_distance_method("Proximity", proximity_type = "rfgap")
  expect_equal(nrow(rf$get_similar_cases(iris[1, ], k = 1)), 1)
})

test_that("survival and Gower models use added cases", {
  lung2 <- na.omit(survival::lung[, c("time", "status", "age", "sex")])
  lung2$status <- lung2$status - 1
  m <- CoxModel$new(survival::Surv(time, status) ~ age + sex, lung2[1:150, ])
  m$fit()
  m$add_cases(lung2[151:nrow(lung2), ])
  s <- m$predict_survival(lung2[1, ], k = nrow(lung2), times = 365)
  ref <- summary(survival::survfit(survival::Surv(time, status) ~ 1, lung2), times = 365)$surv
  expect_equal(as.numeric(s), ref)

  g <- GowerModel$new(Species ~ ., iris[1:100, ])
  g$fit()
  g$add_cases(iris[101:150, ], refit = TRUE)
  expect_equal(as.character(g$predict_outcome(iris[150, ], k = 1)$prediction), "virginica")
})
