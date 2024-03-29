# Generated by using Rcpp::compileAttributes() -> do not edit by hand
# Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

cpp_weightedDistance <- function(x, weights) {
    .Call(`_CaseBasedReasoning_cpp_weightedDistance`, x, weights)
}

cpp_weightedDistanceXY <- function(x, y, weights) {
    .Call(`_CaseBasedReasoning_cpp_weightedDistanceXY`, x, y, weights)
}

cpp_TerminalNodeDistance <- function(terminalNodeIDs) {
    .Call(`_CaseBasedReasoning_cpp_TerminalNodeDistance`, terminalNodeIDs)
}

cpp_proximityMatrix <- function(nodeIDs) {
    .Call(`_CaseBasedReasoning_cpp_proximityMatrix`, nodeIDs)
}

cpp_proximityMatrixRangerXY <- function(xNodeIDs, yNodeIDs) {
    .Call(`_CaseBasedReasoning_cpp_proximityMatrixRangerXY`, xNodeIDs, yNodeIDs)
}

cpp_depthMatrix <- function(xNodeIDs, terminalNodeIDs) {
    .Call(`_CaseBasedReasoning_cpp_depthMatrix`, xNodeIDs, terminalNodeIDs)
}

cpp_depthMatrixRangerXY <- function(xNodeIDs, yNodeIDs, terminalNodeIDs) {
    .Call(`_CaseBasedReasoning_cpp_depthMatrixRangerXY`, xNodeIDs, yNodeIDs, terminalNodeIDs)
}

cpp_orderMatrix <- function(x, sortDirection, k = 5L) {
    .Call(`_CaseBasedReasoning_cpp_orderMatrix`, x, sortDirection, k)
}

cpp_orderVector <- function(x, sortDirection, k = 0L) {
    .Call(`_CaseBasedReasoning_cpp_orderVector`, x, sortDirection, k)
}

#' @importFrom RcppParallel RcppParallelLibs
NULL

cpp_weighted_knn <- function(x, query, weights, k) {
    .Call(`_CaseBasedReasoning_cpp_weighted_knn`, x, query, weights, k)
}

