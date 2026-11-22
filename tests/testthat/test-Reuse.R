# Predictions of class and numeric outcomes from retrieved cases (#43)

test_that("class predictions are the majority of the k nearest cases", {
  set.seed(1)
  rf <- RFModel$new(Species ~ ., iris[-c(1, 51, 101), ], num.trees = 50)
  rf$fit()
  q <- iris[c(1, 51, 101), ]
  pred <- rf$predict_outcome(q, k = 7)
  expect_s3_class(pred$prediction, "factor")
  expect_equal(levels(pred$prediction), levels(iris$Species))
  expect_named(pred, c("prediction", paste0("prob_", levels(iris$Species))))
  expect_equal(rowSums(pred[, -1]), rep(1, 3), ignore_attr = TRUE)

  sc <- rf$get_similar_cases(q, k = 7)
  for (i in 1:3) {
    tab <- table(factor(sc$Species[(i - 1) * 7 + 1:7], levels = levels(iris$Species))) / 7
    expect_equal(unname(unlist(pred[i, -1])), as.numeric(tab))
    expect_equal(as.character(pred$prediction[i]), names(tab)[which.max(tab)])
  }
})

test_that("numeric predictions are the (weighted) mean of the k nearest cases", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length + Species, iris[-(1:5), ])
  m$fit()
  q <- iris[1:5, ]
  sc <- m$get_similar_cases(q, k = 4)
  pred <- m$predict_outcome(q, k = 4)
  expect_equal(pred$prediction, as.numeric(tapply(sc$Sepal.Length, rep(1:5, each = 4), mean)),
               ignore_attr = TRUE)

  pw <- m$predict_outcome(q, k = 4, weighted = TRUE)
  d <- matrix(sc$scDist, nrow = 4)
  y <- matrix(sc$Sepal.Length, nrow = 4)
  ref <- vapply(1:5, function(i) {
    h <- max(d[, i]) * 1.0001 + .Machine$double.eps
    w <- (1 - (d[, i] / h)^3)^3
    sum(w * y[, i]) / sum(w)
  }, numeric(1))
  expect_equal(pw$prediction, ref)
})

test_that("0/1 and logical endpoints are classes", {
  inf <- infert
  m <- LogisticModel$new(case ~ age + parity + spontaneous + induced, inf)
  m$fit()
  pred <- m$predict_outcome(inf[1:3, ], k = 15, exclude_self = TRUE)
  expect_equal(levels(pred$prediction), c("0", "1"))
  expect_named(pred, c("prediction", "prob_0", "prob_1"))
})

test_that("evaluate() reports accuracy, Brier score and log loss for classes", {
  set.seed(2)
  idx <- sample(nrow(iris), 100)
  rf <- RFModel$new(Species ~ ., iris[idx, ], num.trees = 50)
  rf$fit()
  test <- iris[-idx, ]
  pred <- rf$predict_outcome(test, k = 5)
  ev <- rf$evaluate(test, k = 5)
  expect_equal(ev$accuracy, mean(pred$prediction == test$Species))
  P <- as.matrix(pred[, -1])
  Y <- outer(as.character(test$Species), levels(iris$Species), "==") * 1
  expect_equal(ev$brier, mean(rowSums((P - Y)^2)))
  expect_equal(ev$log_loss, -mean(log(pmax(rowSums(P * Y), 1e-15))))
  expect_equal(ev$n, nrow(test))
  expect_gt(ev$accuracy, 0.85)
})

test_that("evaluate() reports RMSE and MAE for numeric endpoints", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length, iris[1:100, ])
  m$fit()
  test <- iris[101:150, ]
  pred <- m$predict_outcome(test, k = 5)$prediction
  ev <- m$evaluate(test, k = 5)
  expect_equal(ev$rmse, sqrt(mean((pred - test$Sepal.Length)^2)))
  expect_equal(ev$mae, mean(abs(pred - test$Sepal.Length)))
})

test_that("evaluate() delegates to evaluate_survival() for survival endpoints", {
  lung2 <- na.omit(survival::lung[, c("time", "status", "age", "sex", "ph.ecog")])
  lung2$status <- lung2$status - 1
  m <- CoxModel$new(survival::Surv(time, status) ~ age + sex + ph.ecog, lung2[1:150, ])
  m$fit()
  expect_equal(m$evaluate(lung2[151:nrow(lung2), ], k = 20),
               m$evaluate_survival(lung2[151:nrow(lung2), ], k = 20))
  expect_error(m$predict_outcome(lung2[1, ]), "predict_survival")
})

test_that("exclude_self gives leave-one-out predictions", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length, iris)
  m$fit()
  p_in <- m$predict_outcome(iris[1:3, ], k = 1)$prediction
  expect_equal(p_in, iris$Sepal.Length[1:3])
  p_loo <- m$predict_outcome(iris[1:3, ], k = 1, exclude_self = TRUE)$prediction
  sc <- m$get_similar_cases(iris[1:3, ], k = 1, exclude_self = TRUE)
  expect_equal(p_loo, sc$Sepal.Length)
  expect_error(m$predict_outcome(iris[1, ], k = 150, exclude_self = TRUE), "larger than")
})

test_that("predict() S3 method dispatches on type", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length, iris)
  m$fit()
  expect_equal(nrow(predict(m, iris[1:2, ])), 2)
  expect_equal(predict(m, iris[1:2, ], type = "outcome"),
               m$predict_outcome(iris[1:2, ], k = 10))
  expect_equal(predict(m, iris[1:2, ], k = 3, type = "outcome", weighted = TRUE),
               m$predict_outcome(iris[1:2, ], k = 3, weighted = TRUE))
})
