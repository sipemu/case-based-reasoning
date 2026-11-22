library(testthat)
library(CaseBasedReasoning)

# CRAN policy: use at most 2 cores
RcppParallel::setThreadOptions(numThreads = 2)

test_check("CaseBasedReasoning")
