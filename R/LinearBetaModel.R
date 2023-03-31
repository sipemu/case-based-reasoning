#' Linear Regression Model for Case-Based-Reasoning
#'
#' @export
LinearBetaModel <- R6Class(
  classname = "LinearBetaModel",
  inherit   = RegressionModel,
  public    = list(
    #' @field model the statistical model
    model       = 'ols'
  )
)