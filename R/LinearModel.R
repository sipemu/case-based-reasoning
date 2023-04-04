#' Linear Regression Model for Case-Based-Reasoning
#'
#' @export
LinearModel <- R6Class(
  classname = "LinearModel",
  inherit   = RegressionModel,
  public    = list(
    #' @field model the statistical model
    model       = 'ols'
  )
)