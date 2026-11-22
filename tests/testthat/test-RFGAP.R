# OOB and RF-GAP proximities (#20)

make_forest <- function(seed = 1, ...) {
  set.seed(seed)
  df <- data.frame(x1 = runif(120), x2 = runif(120), x3 = rnorm(120))
  df$y <- 3 * df$x1 + sin(6 * df$x2) + rnorm(120, sd = 0.2)
  rf <- ranger::ranger(y ~ ., df, num.trees = 60, keep.inbag = TRUE, ...)
  list(df = df, rf = rf, x = df[, c("x1", "x2", "x3")])
}

test_that("RF-GAP reproduces the out-of-bag prediction in-sample", {
  f <- make_forest()
  p <- proximity_distance(f$x, rfObject = f$rf, type = "rfgap", as_dist = FALSE)
  expect_equal(dim(p), c(120, 120))
  expect_equal(unname(colSums(p)), rep(1, 120))
  expect_true(all(diag(p) == 0))
  # column q holds the proximities of query q to all training cases
  expect_equal(as.numeric(f$df$y %*% p), f$rf$predictions)
})

test_that("RF-GAP reproduces predict() for new data", {
  f <- make_forest(seed = 2)
  set.seed(3)
  new <- data.frame(x1 = runif(7), x2 = runif(7), x3 = rnorm(7))
  p <- proximity_distance(f$x, new, rfObject = f$rf, type = "rfgap", as_dist = FALSE)
  expect_equal(dim(p), c(120, 7))
  expect_equal(unname(colSums(p)), rep(1, 7))
  expect_equal(as.numeric(f$df$y %*% p), predict(f$rf, new)$predictions)
})

test_that("OOB proximity only uses trees where both cases are out-of-bag", {
  f <- make_forest(seed = 4)
  p <- proximity_distance(f$x, rfObject = f$rf, type = "oob", as_dist = FALSE)
  tn <- terminal_nodes(f$x, f$rf)
  oob <- do.call(cbind, f$rf$inbag.counts) == 0
  ref <- function(i, j) {
    both <- oob[i, ] & oob[j, ]
    if (!any(both)) return(0)
    mean(tn[i, both] == tn[j, both])
  }
  for (ij in list(c(1, 2), c(5, 40), c(17, 99))) {
    expect_equal(p[ij[1], ij[2]], ref(ij[1], ij[2]))
  }
  expect_equal(p, t(p))
})

test_that("OOB and RF-GAP types give informative errors", {
  set.seed(1)
  rf <- ranger::ranger(Species ~ ., iris, num.trees = 5)
  expect_error(proximity_distance(iris[, -5], rfObject = rf, type = "rfgap"), "keep.inbag")
  rf2 <- ranger::ranger(Species ~ ., iris, num.trees = 5, keep.inbag = TRUE)
  expect_error(proximity_distance(iris[1:10, -5], rfObject = rf2, type = "oob"), "training data")
})

test_that("RFModel supports RF-GAP retrieval", {
  set.seed(5)
  m <- RFModel$new(Sepal.Length ~ ., iris, num.trees = 50)
  m$fit()
  m$set_distance_method("Proximity", proximity_type = "rfgap")
  expect_equal(m$proximity_type, "rfgap")
  sc <- m$get_similar_cases(iris[c(1, 51, 101), ], k = 4)
  expect_equal(nrow(sc), 12)
  expect_true(all(sc$scDist >= 0 & sc$scDist <= 1))
  d_in <- m$calc_distance_matrix()
  expect_equal(dim(d_in), c(150, 150))
  expect_error(m$set_distance_method("Proximity", proximity_type = "foo"))
})
