# Regression tests for correctness issues (#4 - #18) and value checks for the
# distance functions (#26).

ovarian_factors <- function() {
  ov <- survival::ovarian
  ov$rx <- factor(ov$rx)
  ov$resid.ds <- factor(ov$resid.ds)
  ov$ecog.ps <- factor(ov$ecog.ps)
  ov
}

test_that("query factor levels are matched by name, not by code (#4)", {
  ov <- ovarian_factors()
  m <- CoxModel$new(survival::Surv(futime, fustat) ~ age + rx, ov)
  m$fit()
  q <- ov[ov$rx == 2, ][1:2, ]
  q_dropped <- q
  q_dropped$rx <- droplevels(q_dropped$rx)
  q_char <- q
  q_char$rx <- as.character(q_char$rx)
  d <- m$calc_distance_matrix(q)
  expect_equal(m$calc_distance_matrix(q_dropped), d)
  expect_equal(m$calc_distance_matrix(q_char), d)

  # same for the random forest
  set.seed(1)
  rf <- RFModel$new(Sepal.Length ~ ., iris, num.trees = 20)
  rf$fit()
  rf$set_distance_method("Proximity")
  qi <- iris[101:103, ]
  qi_dropped <- qi
  qi_dropped$Species <- droplevels(qi_dropped$Species)
  expect_equal(rf$calc_distance_matrix(qi_dropped), rf$calc_distance_matrix(qi))

  # unknown levels are an error
  q_bad <- q_char
  q_bad$rx[1] <- "3"
  expect_error(m$calc_distance_matrix(q_bad), "Unknown level")
})

test_that("character predictors work after fit() (#5)", {
  ov <- ovarian_factors()
  ov_chr <- ov
  ov_chr$rx <- as.character(ov_chr$rx)
  m_fct <- CoxModel$new(survival::Surv(futime, fustat) ~ age + rx, ov)
  m_fct$fit()
  m_chr <- CoxModel$new(survival::Surv(futime, fustat) ~ age + rx, ov_chr)
  expect_warning(m_chr$fit(), "transformed to class factor")
  expect_equal(m_chr$calc_distance_matrix(ov_chr[1:3, ]),
               m_fct$calc_distance_matrix(ov[1:3, ]))
})

test_that("training rows with NA are excluded from retrieval (#6)", {
  ov <- ovarian_factors()
  ov$age[1] <- NA
  m <- CoxModel$new(survival::Surv(futime, fustat) ~ age + rx, ov)
  expect_warning(m$fit(), "Dropped cases with missing values: 1")
  sc <- m$get_similar_cases(ov[2, ], k = 3)
  expect_equal(nrow(sc), 3)
  expect_false(anyNA(sc$scDist))
  expect_equal(nrow(m$dist_matrix), nrow(ov) - 1)

  # NA in the query is an informative error
  expect_error(m$get_similar_cases(ov[1, ], k = 1), "Missing values in query")
})

test_that("k is validated (#7)", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width, iris[1:5, ])
  m$fit()
  expect_error(m$get_similar_cases(iris[6, ], k = 10), "larger than the number")
  expect_error(m$get_similar_cases(iris[6, ], k = 1.5), "whole number")
  expect_equal(nrow(m$get_similar_cases(iris[6, ], k = 5)), 5)
})

test_that("merge = TRUE works without endpoint columns in the query (#8)", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Species, iris)
  m$fit()
  q <- iris[1:2, c("Sepal.Width", "Species")]
  res <- m$get_similar_cases(q, k = 2, merge = TRUE)
  expect_equal(nrow(res), 2 * 3)
  expect_equal(res$group, rep(c("Query", "Matched", "Matched"), 2))
  expect_true(all(is.na(res$Sepal.Length[res$group == "Query"])))
  expect_equal(res$scCaseId, rep(1:2, each = 3))
})

test_that("variable_selection() returns the fastbw() selection (#9)", {
  set.seed(42)
  n <- 300
  df <- data.frame(x1 = rnorm(n), noise = rnorm(n))
  df$y <- 2 * df$x1 + rnorm(n)
  m <- LinearModel$new(y ~ x1 + noise, df)
  sel <- m$variable_selection()
  expect_equal(sel, "x1")
  expect_equal(m$terms, c("x1", "noise"))

  m$variable_selection(update = TRUE)
  expect_equal(m$terms, "x1")
  expect_equal(all.vars(m$formula), c("y", "x1"))
  expect_error(m$get_similar_cases(df[1, ]), "not trained")
  m$fit()
  expect_equal(nrow(m$get_similar_cases(df[1, ], k = 2)), 2)
})

test_that("proximity distance is sqrt(1 - proximity), independent of the batch (#10)", {
  set.seed(1)
  rf <- ranger::ranger(Species ~ ., iris, num.trees = 50)
  x <- iris[1:50, -5]
  y <- iris[51:60, -5]
  d1 <- proximity_distance(x, y, rf)
  d2 <- proximity_distance(x, y[1:2, ], rf)
  expect_equal(d1[, 1:2], d2)

  tx <- terminal_nodes(x, rf)
  ty <- terminal_nodes(y, rf)
  prox <- outer(seq_len(nrow(tx)), seq_len(nrow(ty)),
                Vectorize(function(i, j) mean(tx[i, ] == ty[j, ])))
  expect_equal(d1, sqrt(1 - prox))

  # within-x dist object
  dx <- proximity_distance(x[1:10, ], rfObject = rf)
  expect_s3_class(dx, "dist")
  px <- outer(1:10, 1:10, Vectorize(function(i, j) mean(tx[i, ] == tx[j, ])))
  expect_equal(unname(as.matrix(dx)), sqrt(1 - px), ignore_attr = TRUE)
})

test_that("depth distance equals the edge count between terminal nodes (#26)", {
  set.seed(3)
  rf <- ranger::ranger(Sepal.Length ~ ., iris[, 1:4], num.trees = 3, min.node.size = 20)
  x <- iris[1:30, 2:4]
  tn <- terminal_nodes(x, rf)

  # reference implementation in R: walk to the root, count edges to the LCA
  path_to_root <- function(tree, node) {
    left <- rf$forest$child.nodeIDs[[tree]][[1]]
    right <- rf$forest$child.nodeIDs[[tree]][[2]]
    path <- node
    while (node != 0) {
      node <- which(left == node | right == node) - 1
      path <- c(path, node)
    }
    path
  }
  edges <- function(tree, a, b) {
    pa <- path_to_root(tree, a)
    pb <- path_to_root(tree, b)
    lca <- pa[pa %in% pb][1]
    (match(lca, pa) - 1) + (match(lca, pb) - 1)
  }
  ref <- outer(1:30, 1:30, Vectorize(function(i, j) {
    sum(vapply(1:3, function(t) edges(t, tn[i, t], tn[j, t]), numeric(1)))
  }))

  d <- depth_distance(x, rfObject = rf)
  expect_equal(unname(as.matrix(d)), ref, ignore_attr = TRUE)
  dxy <- depth_distance(x[1:10, ], x[11:30, ], rf)
  expect_equal(dxy, ref[1:10, 11:30])
})

test_that("exclude_self drops the query case itself (#13)", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Petal.Length, iris)
  m$fit()
  q <- iris[c(5, 77), ]
  with_self <- m$get_similar_cases(q, k = 1)
  expect_equal(rownames(with_self), c("5", "77"))
  without_self <- m$get_similar_cases(q, k = 1, exclude_self = TRUE)
  expect_false(any(rownames(without_self) %in% c("5", "77")))
})

test_that("weighted_distance() defaults to equal weights and checks input (#14)", {
  x <- matrix(c(0, 1, 0, 0, 0, 1), 2, byrow = TRUE)
  expect_equal(as.numeric(weighted_distance(x)), 2)
  set.seed(1)
  a <- matrix(rnorm(12), 4)
  b <- matrix(rnorm(6), 2)
  w <- c(1, 2, 0.5)
  ref <- outer(1:4, 1:2, Vectorize(function(i, j) sum(abs(w * (a[i, ] - b[j, ])))))
  expect_equal(weighted_distance(a, b, w), ref)
  expect_error(weighted_distance(a, b, c(1, 2)), "one element per column")
})

test_that("RFModel respects verbose (#15)", {
  expect_false(RFModel$new(Species ~ ., iris)$model_params$verbose)
  expect_true(RFModel$new(Species ~ ., iris, verbose = TRUE)$model_params$verbose)
})

test_that("threads argument does not change the global setting (#17)", {
  old <- Sys.getenv("RCPP_PARALLEL_NUM_THREADS", unset = NA)
  set.seed(1)
  rf <- ranger::ranger(Species ~ ., iris, num.trees = 5)
  distance_random_forest(iris[1:10, -5], rfObject = rf, threads = 1)
  expect_identical(Sys.getenv("RCPP_PARALLEL_NUM_THREADS", unset = NA), old)
})

test_that("regression weights are not double-named (#18)", {
  m <- LinearModel$new(Sepal.Length ~ Sepal.Width + Species, iris)
  m$fit()
  expect_named(m$weights, c("Sepal.Width", "Species"))
  expect_null(names(m$weights$Sepal.Width))
  expect_named(m$weights$Species, levels(iris$Species))
})

test_that("contribution-space distance equals the main-effects weighted distance (#22)", {
  ov <- ovarian_factors()
  m <- CoxModel$new(survival::Surv(futime, fustat) ~ age + rx + ecog.ps, ov)
  m$fit()
  b <- stats::coef(m$model_fit)
  q <- ov[c(3, 10), ]
  ref <- outer(seq_len(nrow(ov)), seq_len(nrow(q)), Vectorize(function(i, j) {
    abs(b["age"] * (ov$age[i] - q$age[j])) +
      abs(m$weights$rx[as.character(ov$rx[i])] - m$weights$rx[as.character(q$rx[j])]) +
      abs(m$weights$ecog.ps[as.character(ov$ecog.ps[i])] - m$weights$ecog.ps[as.character(q$ecog.ps[j])])
  }))
  expect_equal(unname(m$calc_distance_matrix(q)), unname(ref))
})

test_that("splines and interactions are supported (#11)", {
  ov <- ovarian_factors()
  m <- CoxModel$new(survival::Surv(futime, fustat) ~ rcs(age, 3) + rx, ov)
  expect_equal(m$terms, c("rcs(age, 3)", "rx"))
  expect_equal(m$variables, c("age", "rx"))
  expect_equal(m$endpoint, c("futime", "fustat"))
  m$fit()
  expect_named(m$weights$`rcs(age, 3)`, c("age", "age'"))
  sc <- m$get_similar_cases(ov[1:2, ], k = 3)
  expect_equal(nrow(sc), 6)

  # contribution of the spline term = linear predictor part of that term
  b <- stats::coef(m$model_fit)
  X <- stats::predict(m$model_fit, ov, type = "x")
  c_age <- as.numeric(X[, 1:2] %*% b[1:2])
  c_rx <- as.numeric(X[, 3] * b[3])
  ref <- abs(outer(c_age, c_age[1:2], "-")) + abs(outer(c_rx, c_rx[1:2], "-"))
  expect_equal(unname(m$calc_distance_matrix(ov[1:2, ])), ref)

  # interaction
  m2 <- LinearModel$new(Sepal.Length ~ Sepal.Width * Species, iris)
  m2$fit()
  expect_equal(m2$terms, c("Sepal.Width", "Species", "Sepal.Width:Species"))
  expect_equal(dim(m2$calc_distance_matrix(iris[1:4, ])), c(150, 4))
  expect_equal(m2$calc_distance_matrix(iris[1:4, ])[1, 1], 0)
})

test_that("variable_selection() maps rms term names to formula labels", {
  set.seed(7)
  n <- 300
  df <- data.frame(x1 = runif(n, 0, 10), noise = rnorm(n))
  df$y <- sin(df$x1) + df$x1 + rnorm(n, sd = 0.3)
  m <- LinearModel$new(y ~ rcs(x1, 4) + noise, df)
  expect_equal(m$variable_selection(), "rcs(x1, 4)")
  m$variable_selection(update = TRUE)
  expect_equal(m$variables, "x1")
})
