# Gower distance and GowerModel (#44)

mixed_data <- function() {
  set.seed(1)
  n <- 30
  data.frame(
    num = rnorm(n),
    int = sample(1:10, n, TRUE),
    fct = factor(sample(c("a", "b", "c"), n, TRUE)),
    ord = factor(sample(c("low", "mid", "high"), n, TRUE),
                 levels = c("low", "mid", "high"), ordered = TRUE),
    lgl = sample(c(TRUE, FALSE), n, TRUE),
    y = rnorm(n)
  )
}

gower_ref <- function(x, y, w = rep(1, ncol(x)), ranges) {
  outer(seq_len(nrow(x)), seq_len(nrow(y)), Vectorize(function(i, j) {
    d <- vapply(names(x), function(v) {
      a <- x[[v]][i]; b <- y[[v]][j]
      if (is.ordered(a)) abs(as.integer(a) - as.integer(b)) / (nlevels(a) - 1)
      else if (is.factor(a)) as.numeric(a != b)
      else abs(as.numeric(a) - as.numeric(b)) / diff(ranges[[v]])
    }, numeric(1))
    sum(w * d) / sum(w)
  }))
}

test_that("gower_distance() matches the definition", {
  df <- mixed_data()[, 1:5]
  rng <- lapply(df[c("num", "int", "lgl")], function(v) range(as.numeric(v)))
  ref <- gower_ref(df, df, ranges = rng)
  d <- gower_distance(df)
  expect_s3_class(d, "dist")
  expect_equal(unname(as.matrix(d)), ref, ignore_attr = TRUE)

  w <- c(num = 2, fct = 0.5)
  ww <- c(2, 1, 0.5, 1, 1)
  expect_equal(unname(as.matrix(gower_distance(df, weights = w))),
               gower_ref(df, df, ww, rng), ignore_attr = TRUE)
  expect_equal(unname(as.matrix(gower_distance(df, weights = ww))),
               gower_ref(df, df, ww, rng), ignore_attr = TRUE)
})

test_that("gower_distance() agrees with cluster::daisy()", {
  skip_if_not_installed("cluster")
  df <- mixed_data()[, 1:4]
  ref <- cluster::daisy(df, metric = "gower")
  expect_equal(as.numeric(gower_distance(df)), as.numeric(ref))
  w <- c(1, 3, 0.5, 2)
  ref_w <- cluster::daisy(df, metric = "gower", weights = w)
  expect_equal(as.numeric(gower_distance(df, weights = w)), as.numeric(ref_w))
})

test_that("query distances use the training ranges and ignore missing values", {
  df <- mixed_data()[, 1:5]
  x <- df[1:20, ]
  y <- df[21:30, ]
  d <- gower_distance(x, y)
  expect_equal(dim(d), c(20, 10))
  expect_equal(gower_distance(x, y[1:2, ]), d[, 1:2])

  y_na <- y[1, ]
  y_na$num <- NA
  d_na <- gower_distance(x, y_na)
  ref <- gower_distance(x[, -1], y_na[, -1])
  expect_equal(d_na, ref)

  expect_error(gower_distance(x, y, weights = c(foo = 1)), "Unknown variable")
  expect_error(gower_distance(x, y, weights = c(1, 2)), "one element per variable")
})

test_that("GowerModel retrieves the nearest cases by Gower distance", {
  df <- mixed_data()
  m <- GowerModel$new(y ~ num + int + fct + ord + lgl, df[1:25, ])
  m$fit()
  q <- df[26:30, ]
  d <- m$calc_distance_matrix(q)
  ref <- gower_distance(df[1:25, 1:5], q[, 1:5])
  expect_equal(unname(d), unname(ref))

  sc <- m$get_similar_cases(q, k = 3)
  expect_equal(sc$scDist, as.numeric(apply(ref, 2, function(v) sort(v)[1:3])))
  pred <- m$predict_outcome(q, k = 3)
  expect_equal(pred$prediction, as.numeric(tapply(sc$y, rep(1:5, each = 3), mean)), ignore_attr = TRUE)
  expect_equal(predict(m, q, type = "outcome", k = 3), pred)
})

test_that("ordered factors stay ordered in queries", {
  df <- mixed_data()
  m <- GowerModel$new(y ~ ord, df)
  m$fit()
  q <- df[1:3, ]
  q$ord <- as.character(q$ord)
  expect_equal(m$calc_distance_matrix(q), m$calc_distance_matrix(df[1:3, ]))
  # low vs high is twice as far as low vs mid
  q2 <- data.frame(ord = c("mid", "high"))
  low <- which(df$ord == "low")[1]
  d <- m$calc_distance_matrix(q2)
  expect_equal(d[low, 2], 2 * d[low, 1])
})

test_that("GowerModel explains matches per variable and works with survival endpoints", {
  df <- mixed_data()
  m <- GowerModel$new(y ~ num + fct + ord, df[1:25, ], weights = c(num = 2))
  m$fit()
  q <- df[26, ]
  sc <- m$get_similar_cases(q, k = 1)
  ex <- m$explain_match(q, sc)
  expect_equal(sum(ex$distance), sc$scDist)
  expect_equal(sum(ex$share), 1)
  expect_equal(ex$weight[ex$variable == "num"], 2)

  lung2 <- na.omit(survival::lung[, c("time", "status", "age", "sex", "ph.ecog")])
  lung2$status <- lung2$status - 1
  g <- GowerModel$new(survival::Surv(time, status) ~ age + sex + ph.ecog, lung2[1:150, ])
  g$fit()
  ev <- g$evaluate(lung2[151:nrow(lung2), ], k = 20)
  expect_true(ev$c_index > 0.4 && ev$c_index < 1)
})
