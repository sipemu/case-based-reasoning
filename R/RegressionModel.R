#' Root class for Regression Models, e.g., CPH, logistic, and linear regression
#'
#' @keywords data-preparation
RegressionModel <- R6Class(
  classname = "RegressionModel",
  inherit = CBRBase,
  public = list(
    #' @field model_params rms arguments
    model_params = list(x = TRUE, y = TRUE),
    #' @field weights Weights for distance calculation
    weights     = NULL,
    #' @description
    #' Prints information of the initialized object
    print = function() {
      cat("Case-Based-Reasoning based Regression Coefficients\n")
      cat("---------------------------------------\n")
      cat("Model     : ", paste(self$model, collapse = ", "), "\n")
      cat("Endpoint  : ", paste(self$endpoint, collapse = ", "), "\n")
      cat("Variables : ", paste(self$terms, collapse = ", "), "\n")
      cat("Trained   : ", ifelse(is.null(self$weights), FALSE, TRUE), "\n")
    },
    #' @description
    #' Fast backward variable selection with penalization (\code{rms::fastbw})
    #'
    #' @param update If \code{TRUE}, restrict the model's formula and terms to the
    #'   selected variables. The model must then be fitted again with \code{$fit()}.
    #' @param ... Further arguments passed to \code{rms::fastbw}, e.g.
    #'   \code{rule} or \code{sls}.
    #' @return Character vector of the selected (retained) variables.
    variable_selection = function(update = FALSE, ...) {
      train_tbl <- private$prepare_training()
      fit <- private$fit_model(train_tbl)

      # Variable Selection; fastbw() reports rms term names (fit$Design$name),
      # which are mapped to the term labels of the formula
      vars <- rms::fastbw(fit = fit, type = "i", ...)
      term_labels <- names(fit$assign)
      selected_vars <- term_labels[fit$Design$name %in% vars$names.kept]

      if (isTRUE(update)) {
        if (length(selected_vars) == 0) {
          stop("No variables retained by fastbw(); formula not updated.")
        }
        formula <- stats::reformulate(selected_vars, response = self$formula[[2]])
        environment(formula) <- environment(self$formula)
        self$formula <- formula
        self$terms <- selected_vars
        self$variables <- setdiff(all.vars(stats::delete.response(stats::terms(formula))), self$endpoint)
        self$model_fit <- NULL
        self$weights <- NULL
        private$train_idx <- NULL
      }
      selected_vars
    },
    #' @description
    #' Fit the regression model
    fit = function() {
      train_tbl <- private$prepare_training()
      self$model_fit <- private$fit_model(train_tbl)
      coefs <- stats::coef(self$model_fit)

      weights <- vector("list", length(self$terms))
      names(weights) <- self$terms
      for (v in self$terms) {
        idx <- self$model_fit$assign[[v]]
        lev <- private$factor_levels[[v]]
        if (!is.null(lev) && v %in% self$variables) {
          # factor main effect: reference level 0, others coefficient "var=level"
          w <- c(0, unname(coefs[paste0(v, "=", lev[-1])]))
          names(w) <- lev
        } else if (v %in% self$variables) {
          # numeric main effect
          w <- unname(coefs[idx])
        } else {
          # other terms (splines, interactions, ...): named coefficients
          w <- coefs[idx]
        }
        weights[[v]] <- w
      }
      self$weights <- weights
      invisible(self)
    }
  ),
  private = list(
    fit_model = function(train_tbl) {
      func <- utils::getFromNamespace(self$model, "rms")
      params <- self$model_params
      params$data <- train_tbl
      params$formula <- self$formula
      do.call(func, params)
    },
    # check weights on NA
    check_weights = function() {
      wNA <- vapply(self$weights, function(x) any(is.na(x)), logical(1))
      if (any(wNA)) {
        warning("Variables: ", paste(names(wNA)[wNA], collapse = ", "), " have NA weights.")
        return(TRUE)
      }
      return(FALSE)
    },
    # contribution of each term to the linear predictor: for term t with
    # design columns X_t and coefficients b_t, c_t(x) = X_t(x) %*% b_t.
    # For main effects this gives b * x (numeric) and the level coefficient
    # (factor), i.e. the weighted distance of Dippon et al. (2002).
    contributions = function(df) {
      fit <- self$model_fit
      coefs <- stats::coef(fit)
      X <- stats::predict(fit, newdata = df, type = "x")
      X <- matrix(X, nrow = nrow(df))
      # columns of X correspond to the non-intercept coefficients in order
      coef_idx <- sort(unlist(fit$assign, use.names = FALSE))
      contrib <- vapply(self$terms, function(v) {
        idx <- fit$assign[[v]]
        cols <- match(idx, coef_idx)
        as.numeric(X[, cols, drop = FALSE] %*% coefs[idx])
      }, numeric(nrow(df)))
      matrix(contrib, nrow = nrow(df), dimnames = list(NULL, self$terms))
    },
    # calculate weighted absolute distance in contribution space
    get_distance_matrix = function(query = NULL) {
      if (!is.list(self$weights)) {
        stop("Model not trained: call $fit() first.")
      }
      if (private$check_weights()) {
        stop("NA values in regression beta coefficients!")
      }

      train <- private$contributions(
        private$prepare_newdata(private$training_rows(), "training data")
      )
      query_x <- NULL
      if (!is.null(query)) {
        query_x <- private$contributions(private$prepare_newdata(query))
      }

      # calculate distance matrix
      self$dist_matrix <- as.matrix(weighted_distance(
        x       = train,
        y       = query_x,
        weights = rep(1, ncol(train))
      ))
    }
  )
)


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
    model_params = list(x = TRUE, y = TRUE, surv = TRUE),
    #' @description
    #' Check proportional hazard assumption graphically
    check_ph = function() {
      if (!is.list(self$weights)) {
        stop("The model is not trained: call $fit() first.")
      }
      if (!requireNamespace("patchwork", quietly = TRUE)) {
        stop("Package 'patchwork' is required for check_ph(). Install it with install.packages('patchwork').")
      }
      n <- length(self$terms)
      ggPlot <- list()
      zph <- survival::cox.zph(self$model_fit, "rank")
      for (i in 1:n) {
        df <- data.frame(x = zph$x, y = zph$y[, i])
        g <- ggplot2::ggplot(df, ggplot2::aes(x = x, y = y)) +
          ggplot2::geom_hline(yintercept = 0, colour = "grey") +
          ggplot2::geom_point() +
          ggplot2::geom_smooth(color = "#18BC9C", fill = "#18BC9C") +
          ggplot2::ylab(paste0("Beta(t) of ", self$terms[i])) +
          ggplot2::xlab("Time to Event") +
          ggplot2::theme(panel.grid.major = ggplot2::element_line(colour = "grey90"),
                         panel.grid.minor = ggplot2::element_line(colour = "grey95"))
        ggPlot <- c(ggPlot, list(g))
      }
      return(patchwork::wrap_plots(ggPlot, ncol = 2))
    }
  )
)


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
