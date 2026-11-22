test_that("Matrix ordering", {
  set.seed(1234)
  x <- matrix(rnorm(100), 10)
  xOrder <- CaseBasedReasoning:::cpp_orderMatrix(x, sortDirection = 0, k = 10)
  yOrder <- do.call(cbind, lapply(1:nrow(x), function(col) order(x[, col])))
  expect_equal(xOrder, yOrder)
})

test_that("Matrix ordering honours sortDirection and clamps k", {
  set.seed(1234)
  x <- matrix(rnorm(100), 10)
  desc <- CaseBasedReasoning:::cpp_orderMatrix(x, sortDirection = 1, k = 3)
  expect_equal(desc, do.call(cbind, lapply(1:ncol(x), function(col) order(-x[, col])[1:3])))
  expect_equal(nrow(CaseBasedReasoning:::cpp_orderMatrix(x, sortDirection = 0, k = 50)), 10)
})
