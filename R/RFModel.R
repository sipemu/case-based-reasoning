#' RandomForest Model for Searching Similar Cases
#'
#' This class uses the proximity or depth matrix of the RandomForest algorithm
#' as a similarity matrix of training and query
#' observations. By default all cases with at least one missing values are dropped
#' from learning, calculating the distance matrix and searching for similar
#' cases.
#'
#' @references
#' Englund, C. and Verikas, A. (2012). A novel approach to estimate proximity
#' in a random forest: An exploratory study. Expert Systems with Applications,
#' 39(17), 13046--13050. \doi{10.1016/j.eswa.2012.05.094}
#' @export
RFModel <- R6Class(
  classname = "RFModel",
  inherit = CBRBase,
  public = list(
    #' @field model the statistical model
    model        = 'ranger',
    #' @field model_params model arguments
    model_params = list(write.forest = TRUE, verbose = TRUE),
    #' @field  dist_method Distance method
    dist_method  = "Depth",
    #' @description
    #' Prints information of the initialized object
    print = function() {
      cat("Case-Based-Reasoning with RandomForests\n")
      cat("---------------------------------------\n")
      cat("Model     : ", paste(self$model, collapse = ", "), "\n")
      cat("Endpoints : ", paste(self$endpoint, collapse = ", "), "\n")
      cat("Variables : ", paste(self$terms, collapse = ", "), "\n")
      cat("Method    : ", paste(self$dist_method, collapse = ", "), "\n")
      cat("Trained   : ", ifelse(is.null(self$model_fit), FALSE, TRUE), "\n")
    },
    #' @description
    #' Initialize a RandomForest object for searching similar cases.
    #'
    #' @param formula Object of class formula or character describing the model fit.
    #' @param data Training data of class data.frame
    #' @param ... ranger RandomForest arguments. \code{write.forest} is always
    #'   set to \code{TRUE}; \code{verbose} defaults to \code{FALSE}.
    initialize = function(formula, data, ...) {
      super$initialize(formula, data)
      self$model_params <- list(...)
      self$model_params$write.forest <- TRUE
      if (is.null(self$model_params$verbose)) {
        self$model_params$verbose <- FALSE
      }
    },
    #' @description
    #' Fit the RandomForest
    fit = function() {
      train_tbl <- private$prepare_training()

      # train model
      params <- self$model_params
      params$data <- train_tbl
      params$formula <- self$formula
      self$model_fit <- do.call(ranger::ranger, params)
      invisible(self)
    },
    #' @description
    #' Set the distance method. Available are Proximity and Depth
    #'
    #' @param method Distance calculation method (default: Depth)
    set_distance_method = function(method = "Depth") {
      method <- match.arg(method, c("Proximity", "Depth"))
      self$dist_method <- method
    }
  ),
  private = list(
    explain_pair = function(query, case) {
      validate_ranger(self$model_fit)
      q_nodes <- terminal_nodes(query, self$model_fit)[1, ]
      c_nodes <- terminal_nodes(case, self$model_fit)[1, ]
      explain_forest_match(self$model_fit, q_nodes, c_nodes)
    },
    get_distance_matrix = function(query = NULL) {
      private$ensure_fitted()
      validate_ranger(self$model_fit)
      x <- private$prepare_newdata(private$training_rows(), "training data")
      y <- if (is.null(query)) NULL else private$prepare_newdata(query)
      self$dist_matrix <- distance_random_forest(
        x        = x,
        y        = y,
        method   = self$dist_method,
        rfObject = self$model_fit
      )
    }
  )
)
