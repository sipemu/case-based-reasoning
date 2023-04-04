#' Logistic Regression Model for Case-Based-Reasoning
#'
#' @export
LogisticModel <- R6Class(
  classname = "LogisticModel",
  inherit   = RegressionModel,
  public    = list(
    #' @field model the statistical model
    model       = 'lrm'
  )
)