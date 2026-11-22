# Case-base maintenance (#46)

toy_cases <- function() {
  data.frame(x = c(0, 1, 2, 3, 10, 11, 12, 13, 1.5, 50),
             y = factor(c("a", "a", "a", "a", "b", "b", "b", "b", "b", "c")),
             row.names = c(paste0("a", 1:4), paste0("b", 1:4), "noise", "outlier"))
}

test_that("noisy and pivotal cases are found", {
  m <- GowerModel$new(y ~ x, toy_cases())
  m$fit()
  a <- m$assess_cases(k = 3)
  expect_equal(rownames(a), rownames(toy_cases()))
  expect_equal(attr(a, "k"), 3)
  expect_true(a["noise", "noisy"])
  expect_true(a["outlier", "noisy"])
  expect_equal(as.character(a["outlier", "category"]), "pivotal")
  expect_equal(a["outlier", "n_reachable"], 0L)
  expect_false(any(a[c("a1", "a4", "b1", "b4"), "noisy"]))
  # the noise case is closest to a1, a2, a3: agreement 0
  expect_equal(a["noise", "agreement"], 0)

  m$remove_cases(rownames(a)[a$noisy])
  a2 <- m$assess_cases(k = 3)
  expect_false(any(a2$noisy))
})

test_that("competence categories follow the definitions of Smyth & Keane", {
  set.seed(4)
  idx <- sample(nrow(iris), 60)
  g <- GowerModel$new(Species ~ Sepal.Length + Sepal.Width, iris[idx, ])
  g$fit()
  for (model in list(g)) {
    k <- 4
    a <- model$assess_cases(k = k)
    d <- as.matrix(model$calc_distance_matrix())
    diag(d) <- Inf
    y <- as.character(model$get_case_base()$Species)
    n <- length(y)
    # neighbours in the same order (incl. ties) as the package's ordering
    nn <- lapply(seq_len(n), function(i) {
      o <- CaseBasedReasoning:::cpp_orderMatrix(d[, i, drop = FALSE], 0, k)
      as.integer(o)
    })
    reach <- lapply(seq_len(n), function(i) nn[[i]][y[nn[[i]]] == y[i]])
    cover <- lapply(seq_len(n), function(j) which(vapply(seq_len(n), function(i) j %in% reach[[i]], TRUE)))
    cat_ref <- vapply(seq_len(n), function(i) {
      if (length(reach[[i]]) == 0) return("pivotal")
      ci <- union(i, cover[[i]])
      if (any(vapply(reach[[i]], function(j) all(ci %in% union(j, cover[[j]])), TRUE))) "auxiliary" else "other"
    }, "")
    expect_equal(as.character(a$category), cat_ref)
    expect_equal(a$n_reachable, lengths(reach))
    expect_equal(a$n_coverage, lengths(cover))
    expect_equal(a$agreement, lengths(reach) / k)
    noisy_ref <- vapply(seq_len(n), function(i) {
      tab <- table(y[nn[[i]]]); names(tab)[which.max(tab)] != y[i]
    }, TRUE)
    expect_equal(a$noisy, noisy_ref)
  }
})

test_that("numeric and survival endpoints", {
  m <- LinearModel$new(Sepal.Length ~ Petal.Length, iris)
  m$fit()
  a <- m$assess_cases(k = 5, tolerance = 0.3)
  expect_equal(a$outcome, iris$Sepal.Length)
  expect_true(all(a$agreement >= 0 & a$agreement <= 1))
  expect_true(any(a$noisy) && !all(a$noisy))

  lung2 <- na.omit(survival::lung[, c("time", "status", "age", "sex")])
  lung2$status <- lung2$status - 1
  cm <- CoxModel$new(survival::Surv(time, status) ~ age + sex, lung2)
  cm$fit()
  s <- cm$assess_cases(k = 10, horizon = 365)
  censored_early <- lung2$time <= 365 & lung2$status == 0
  expect_true(all(is.na(s$category[censored_early])))
  expect_true(all(!is.na(s$category[!censored_early])))
  expect_equal(s$outcome[!censored_early & lung2$time > 365], rep("no event", sum(!censored_early & lung2$time > 365)))
})

test_that("random forests use in-sample proximities", {
  set.seed(2)
  rf <- RFModel$new(Species ~ ., iris, num.trees = 50)
  rf$fit()
  rf$set_distance_method("Proximity", proximity_type = "rfgap")
  a <- rf$assess_cases(k = 5)
  expect_equal(nrow(a), 150)
  expect_lt(mean(a$noisy), 0.2)
})
