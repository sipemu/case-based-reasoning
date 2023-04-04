#' Cox-Beta Model for Case-Based-Reasoning
#'
#' Regression beta coefficients obtained from a CPH regression model fitted on the 
#' training data are used for building a weighted distance measure between
#' train and test data. Afterwards, we will use these weights for calculating a 
#' (n x m)-distance matrix, where n is the number of observations in the training data, 
#' and m is the number of observations of the test data. The user can use this 
#' distance matrix for further cluster analysis or for extracting for each test observation 
#' k (= 1,...,l) similar cases from the train data. We use the rms-package for model fitting,
#' variable selection, and checking model assumptions.
#' If the user omits the test data, this functions returns a n x n-distance matrix.
#'
#' @export
CoxModel <- R6Class(
  classname = "CoxModel",
  inherit   = RegressionModel,
  public    = list(
    #' @field model the statistical model
    model        = 'cph',
    #' @field model_params rms arguments
    model_params = list(x = T, y = T, surv = T),
    #' @description 
    #' Check proportional hazard assumption graphically
    check_ph=function() {
      # learn if weights are empty
      testthat::expect_is(self$weights, "list", info = "The model is not trained.")
      n <- length(self$terms)
      ggPlot <- list()
      zph <- survival::cox.zph(self$model_fit, "rank")
      for (i in 1:n) {
        df <- data.frame(x=zph$x, y=zph$y[, i])
        g <- ggplot2::ggplot(df, aes(x=x, y=y)) +
          ggplot2::geom_hline(yintercept=0, colour="grey") +
          ggplot2::geom_point() +
          ggplot2::geom_smooth(color="#18BC9C", fill="#18BC9C") +
          ggplot2::ylab(paste0("Beta(t) of ", self$terms[i])) +
          ggplot2::xlab("Time to Event") +
          cowplot::background_grid(major="xy", minor="xy")
        ggPlot <- c(ggPlot, list(g))
      }
      return(cowplot::plot_grid(plotlist = ggPlot,
                                ncol     = 2))
    }
  )
)