#' Logistic Regression Model for Case-Based-Reasoning
#'
#' @export
LogisticBetaModel <- R6Class(
  classname = "LogisticBetaModel",
  inherit   = RegressionModel,
  public    = list(
    #' @field model the statistical model
    model       = 'lrm'
  )
)