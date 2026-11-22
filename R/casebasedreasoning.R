#' @keywords internal
"_PACKAGE"

#' @import R6
#' @import ranger
#' @importFrom rms fastbw
#' @importFrom survival cox.zph
#' @import Rcpp
#' @importFrom ggplot2 ggplot aes geom_hline geom_point geom_smooth ylab xlab theme element_line
#' @importFrom stats predict as.formula terms
#' @importFrom RcppParallel RcppParallelLibs
#' @useDynLib CaseBasedReasoning, .registration = TRUE
NULL
