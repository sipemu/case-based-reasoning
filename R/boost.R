# Gradient boosting with a SHAP distance

# Design matrix for xgboost: numeric and logical variables as they are,
# ordered factors as their ranks (trees can use the order), unordered factors
# one-hot (all levels). `assign` maps each column to its variable.
boost_design <- function(df, variables) {
  cols <- list()
  assign <- integer(0)
  for (i in seq_along(variables)) {
    v <- df[[variables[i]]]
    if (is.ordered(v)) {
      m <- matrix(as.numeric(v), ncol = 1, dimnames = list(NULL, variables[i]))
    } else if (is.factor(v)) {
      m <- outer(as.character(v), levels(v), "==") * 1
      colnames(m) <- paste0(variables[i], levels(v))
    } else {
      m <- matrix(as.numeric(v), ncol = 1, dimnames = list(NULL, variables[i]))
    }
    cols[[i]] <- m
    assign <- c(assign, rep(i, ncol(m)))
  }
  X <- do.call(cbind, cols)
  attr(X, "assign") <- assign
  X
}

# Objective and label for the endpoint of the training data.
boost_target <- function(df, endpoint) {
  if (length(endpoint) == 2) {
    time <- df[[endpoint[1]]]
    status <- as.numeric(df[[endpoint[2]]])
    if (!all(status %in% c(0, 1))) {
      stop("The status variable '", endpoint[2], "' must be 0/1 or logical.")
    }
    # xgboost's Cox objective: negative times are censored
    return(list(objective = "survival:cox", label = ifelse(status == 1, time, -time),
                classes = NULL, scale = "log relative hazard"))
  }
  out <- prediction_outcome(df, endpoint)
  if (out$type == "class") {
    lev <- out$levels
    label <- match(out$value, lev) - 1
    if (length(lev) == 2) {
      return(list(objective = "binary:logistic", label = label, classes = NULL,
                  scale = "log odds"))
    }
    return(list(objective = "multi:softprob", label = label, classes = lev,
                scale = "log odds (softmax margin) per class"))
  }
  list(objective = "reg:squarederror", label = out$value, classes = NULL,
       scale = "outcome")
}

# SHAP values per variable (columns; for multi-class models, one block of
# variables per class). Dummy columns of a factor are summed, which keeps the
# additivity: rowSums(contributions) + bias = margin of the model.
boost_contributions <- function(fit, X, variables, classes = NULL) {
  phi <- stats::predict(fit, X, predcontrib = TRUE)
  per_class <- if (is.list(phi)) {
    phi
  } else if (length(dim(phi)) == 3) {
    # xgboost >= 2: n x classes x (features + 1)
    lapply(seq_len(dim(phi)[2]), function(k) phi[, k, , drop = TRUE])
  } else {
    list(phi)
  }
  assign <- attr(X, "assign")
  bias <- vapply(per_class, function(p) matrix(p, nrow = nrow(X))[1, ncol(X) + 1], numeric(1))
  blocks <- lapply(per_class, function(p) {
    p <- matrix(p, nrow = nrow(X))
    p <- p[, seq_len(ncol(X)), drop = FALSE]  # drop the bias column
    vapply(seq_along(variables), function(i) rowSums(p[, assign == i, drop = FALSE]),
           numeric(nrow(X)))
  })
  res <- do.call(cbind, lapply(blocks, function(b) matrix(b, nrow = nrow(X))))
  colnames(res) <- if (is.null(classes)) {
    variables
  } else {
    paste0(rep(variables, length(classes)), " [", rep(classes, each = length(variables)), "]")
  }
  attr(res, "bias") <- bias
  res
}

#' Gradient Boosting with a SHAP Distance for Case-Based Reasoning
#'
#' Fits a gradient-boosted tree model with \strong{xgboost} and measures the
#' distance between two cases in the space of their SHAP values (Lundberg et
#' al., 2020). With \eqn{\phi_k(x)} the SHAP value of variable \eqn{k}, i.e. its
#' contribution to the prediction of case \eqn{x} on the margin scale of the
#' model (outcome, log odds or log relative hazard),
#' \deqn{d(x_i, x_j) = \sum_k |\phi_k(x_i) - \phi_k(x_j)|.}
#' This is the contribution-space distance of the regression models with the
#' variables as terms: for a linear model, \eqn{\phi_k(x) = \beta_k (x_k -
#' \bar x_k)}, and the distance is the weighted distance of Dippon et al.
#' (2002). Because the SHAP values add up to the model's prediction, the
#' distance bounds the difference of the predictions on the margin scale; for
#' the Cox objective, \eqn{e^{d}} bounds the hazard ratio of the two cases.
#'
#' The endpoint determines the objective: \code{Surv(time, status)} uses
#' \code{"survival:cox"}, two classes (factor, character, logical or 0/1)
#' \code{"binary:logistic"}, more classes \code{"multi:softprob"} (the SHAP
#' values of all classes are used), and numeric endpoints
#' \code{"reg:squarederror"}. Only the variables of the formula are used, not
#' transformations or interactions: the trees find non-linear effects and
#' interactions themselves. Unordered factors are one-hot encoded and their
#' SHAP values summed per variable; ordered factors are used as their ranks.
#'
#' Every split of the model is part of the distance: choose \code{nrounds}
#' and \code{max_depth} by cross-validation (\code{xgboost::xgb.cv()} with
#' early stopping) rather than by default, otherwise splits in irrelevant
#' features become distance. The \emph{Methods} vignette shows how.
#'
#' Without row or column subsampling (the default), the model and the
#' distance are deterministic. New cases (\code{add_cases()}) need no refit:
#' their SHAP values are computed with the fitted model.
#'
#' @references
#' Lundberg, S. M. et al. (2020). From local explanations to global
#' understanding with explainable AI for trees. Nature Machine Intelligence,
#' 2, 56--67. \doi{10.1038/s42256-019-0138-9}
#'
#' Chen, T. and Guestrin, C. (2016). XGBoost: A scalable tree boosting system.
#' Proceedings of KDD 2016, 785--794. \doi{10.1145/2939672.2939785}
#'
#' @examples
#' \donttest{
#' if (requireNamespace("xgboost", quietly = TRUE)) {
#'   library(survival)
#'   lung2 <- na.omit(lung[, c("time", "status", "age", "sex", "ph.ecog")])
#'   lung2$status <- lung2$status - 1
#'   m <- BoostModel$new(Surv(time, status) ~ age + sex + ph.ecog, lung2, nrounds = 50)
#'   m$fit()
#'   m$get_similar_cases(lung2[1:2, ], k = 3)
#'   m$explain_match(lung2[1, ], lung2[2, ])
#' }
#' }
#' @export
BoostModel <- R6Class(
  classname = "BoostModel",
  inherit = CBRBase,
  public = list(
    #' @field model the learner
    model = "xgboost",
    #' @field model_params xgboost parameters (\code{params}, \code{nrounds})
    model_params = NULL,
    #' @description
    #' Initialize a gradient boosting model for searching similar cases.
    #'
    #' @param formula Object of class formula or character, e.g.
    #'   \code{y ~ x1 + x2} or \code{Surv(time, status) ~ .}.
    #' @param data Training data of class data.frame
    #' @param nrounds number of boosting rounds
    #' @param params list of xgboost parameters, e.g. \code{eta},
    #'   \code{max_depth}, \code{lambda}; \code{objective} is set from the
    #'   endpoint unless given.
    initialize = function(formula, data, nrounds = 100,
                          params = list(eta = 0.1, max_depth = 3)) {
      super$initialize(formula, data)
      if (length(self$endpoint) == 0) {
        stop("BoostModel needs an endpoint, e.g. y ~ x1 + x2.")
      }
      if (!is.numeric(nrounds) || length(nrounds) != 1 || nrounds < 1) {
        stop("'nrounds' must be a positive number.")
      }
      self$model_params <- list(params = params, nrounds = as.integer(nrounds))
    },
    #' @description
    #' Prints information of the initialized object
    print = function() {
      cat("Case-Based-Reasoning with gradient boosting (SHAP distance)\n")
      cat("---------------------------------------\n")
      cat("Endpoint  : ", paste(self$endpoint, collapse = ", "), "\n")
      cat("Variables : ", paste(self$variables, collapse = ", "), "\n")
      cat("Rounds    : ", self$model_params$nrounds, "\n")
      if (!is.null(self$model_fit)) cat("Objective : ", private$target$objective, "\n")
      cat("Trained   : ", !is.null(self$model_fit), "\n")
    },
    #' @description
    #' Fit the boosted trees.
    fit = function() {
      if (!requireNamespace("xgboost", quietly = TRUE)) {
        stop("Package 'xgboost' is required for BoostModel. ",
             "Install it with install.packages('xgboost').")
      }
      train_tbl <- private$prepare_training()
      private$target <- boost_target(train_tbl, self$endpoint)
      X <- boost_design(train_tbl, self$variables)
      params <- self$model_params$params
      if (is.null(params$objective)) params$objective <- private$target$objective
      if (!is.null(private$target$classes) && is.null(params$num_class)) {
        params$num_class <- length(private$target$classes)
      }
      if (is.null(params$nthread)) params$nthread <- 1
      dtrain <- xgboost::xgb.DMatrix(X, label = private$target$label)
      self$model_fit <- xgboost::xgb.train(params = params, data = dtrain,
                                           nrounds = self$model_params$nrounds,
                                           verbose = 0)
      invisible(self)
    },
    #' @description
    #' SHAP values of cases: one column per variable (for multi-class
    #' models, per variable and class), on the margin scale of the model.
    #'
    #' @param data data.frame with the variables of the model
    #' @return A matrix with attribute \code{bias} (the expected margin).
    shap_values = function(data) {
      private$ensure_fitted()
      private$contributions(private$prepare_newdata(data))
    }
  ),
  private = list(
    target = NULL,
    contributions = function(df) {
      X <- boost_design(df, self$variables)
      boost_contributions(self$model_fit, X, self$variables, private$target$classes)
    },
    explain_pair = function(query, case) {
      cq <- private$contributions(private$prepare_newdata(query))
      cc <- private$contributions(private$prepare_newdata(case))
      d <- abs(as.numeric(cq) - as.numeric(cc))
      res <- data.frame(term = colnames(cq),
                        query_contribution = as.numeric(cq),
                        case_contribution  = as.numeric(cc),
                        distance = d,
                        share = if (sum(d) > 0) d / sum(d) else 0,
                        stringsAsFactors = FALSE)
      res <- res[order(-res$distance), , drop = FALSE]
      rownames(res) <- NULL
      res
    },
    get_distance_matrix = function(query = NULL) {
      private$ensure_fitted()
      train <- private$contributions(
        private$prepare_newdata(private$training_rows(), "training data")
      )
      query_x <- if (is.null(query)) NULL else private$contributions(private$prepare_newdata(query))
      self$dist_matrix <- as.matrix(weighted_distance(x = train, y = query_x,
                                                      weights = rep(1, ncol(train))))
    }
  )
)
