#' Gower distance for mixed data
#'
#' Distance of Gower (1971) between the rows of \code{x} (and \code{y}):
#' a weighted mean over the variables of
#' \itemize{
#'   \item numeric and logical variables: \eqn{|x - y| / r}, where \eqn{r} is the
#'     range of the variable;
#'   \item ordered factors: the absolute difference of the level ranks divided
#'     by the number of levels minus one;
#'   \item other factors and characters: 0 if equal, 1 otherwise.
#' }
#' Pairs with a missing value in a variable ignore that variable. The distance
#' is model-free and serves as a baseline for the model-derived distances.
#'
#' @param x a data.frame
#' @param y a second data.frame with the same columns (optional)
#' @param weights non-negative weights of the variables: unnamed (one per
#'   column) or named (variables not named get weight 1). Default: equal
#'   weights.
#' @param ranges named list of ranges (\code{c(min, max)}) of numeric
#'   variables. Default: the ranges in \code{x}, so that distances of new
#'   cases \code{y} do not depend on the other cases in \code{y}.
#'
#' @return a \code{dist} object of the rows of \code{x}, or an
#'   \code{nrow(x)} x \code{nrow(y)} matrix if \code{y} is given.
#'
#' @references
#' Gower, J. C. (1971). A general coefficient of similarity and some of its
#' properties. Biometrics, 27(4), 857--871. \doi{10.2307/2528823}
#'
#' @examples
#' gower_distance(iris[1:5, ])
#' gower_distance(iris[1:100, -5], iris[101:103, -5])
#' @export
gower_distance <- function(x, y = NULL, weights = NULL, ranges = NULL) {
  x <- as.data.frame(x)
  within <- is.null(y)
  if (within) {
    y <- x
  } else {
    y <- as.data.frame(y)
    missing_cols <- setdiff(names(x), names(y))
    if (length(missing_cols) > 0) {
      stop("Columns of 'x' not found in 'y': ", paste(missing_cols, collapse = ", "))
    }
    y <- y[, names(x), drop = FALSE]
  }
  vars <- names(x)
  w <- gower_weights(weights, vars)
  if (is.null(ranges)) ranges <- gower_ranges(x)

  num <- matrix(0, nrow(x), nrow(y))
  den <- matrix(0, nrow(x), nrow(y))
  for (v in vars) {
    if (w[[v]] == 0) next
    d <- gower_variable(x[[v]], y[[v]], ranges[[v]], v)
    ok <- !is.na(d)
    d[!ok] <- 0
    num <- num + w[[v]] * d
    den <- den + w[[v]] * ok
  }
  res <- num / den
  res[den == 0] <- NA
  if (within) {
    return(stats::as.dist(res))
  }
  res
}

# per-variable distance matrix (nrow(x) x nrow(y)), NA for missing values
gower_variable <- function(a, b, range, name) {
  if (is.ordered(a) || is.ordered(b)) {
    lev <- levels(if (is.ordered(a)) a else b)
    ra <- match(as.character(a), lev)
    rb <- match(as.character(b), lev)
    if (anyNA(ra[!is.na(a)]) || anyNA(rb[!is.na(b)])) {
      stop("Values of '", name, "' are not levels of the ordered factor.")
    }
    s <- max(length(lev) - 1, 1)
    return(abs(outer(ra, rb, "-")) / s)
  }
  if (is.factor(a) || is.character(a) || is.factor(b) || is.character(b)) {
    return(outer(as.character(a), as.character(b), "!=") * 1)
  }
  if (!(is.numeric(a) || is.logical(a)) || !(is.numeric(b) || is.logical(b))) {
    stop("Variable '", name, "' must be numeric, logical, a factor or a character.")
  }
  r <- if (is.null(range)) 0 else diff(range)
  d <- abs(outer(as.numeric(a), as.numeric(b), "-"))
  if (!is.finite(r) || r == 0) {
    d[!is.na(d)] <- 0
    return(d)
  }
  d / r
}

# ranges of the numeric and logical variables of a data.frame
gower_ranges <- function(x) {
  is_num <- vapply(x, function(v) (is.numeric(v) || is.logical(v)) && !is.factor(v), logical(1))
  lapply(x[is_num], function(v) range(as.numeric(v), na.rm = TRUE))
}

# weights as a named vector over `vars`
gower_weights <- function(weights, vars) {
  if (is.null(weights)) {
    return(stats::setNames(rep(1, length(vars)), vars))
  }
  if (!is.numeric(weights) || anyNA(weights) || any(weights < 0)) {
    stop("'weights' must be non-negative numbers.")
  }
  if (is.null(names(weights))) {
    if (length(weights) != length(vars)) {
      stop("Unnamed 'weights' must have one element per variable (", length(vars), ").")
    }
    return(stats::setNames(as.numeric(weights), vars))
  }
  unknown <- setdiff(names(weights), vars)
  if (length(unknown) > 0) {
    stop("Unknown variable(s) in 'weights': ", paste(unknown, collapse = ", "))
  }
  w <- stats::setNames(rep(1, length(vars)), vars)
  w[names(weights)] <- weights
  if (sum(w) == 0) stop("At least one weight must be positive.")
  w
}

#' Gower Distance Model for Case-Based-Reasoning
#'
#' A model-free case base: the distance between cases is the Gower distance
#' (\code{\link{gower_distance}}) of the variables on the right-hand side of
#' the formula, optionally weighted. The endpoint (left-hand side) is not used
#' for the distance, but for \code{predict_outcome()},
#' \code{predict_survival()}, \code{evaluate()} and counterfactual cases. Use it
#' as a baseline for the model-derived distances of the other models, or with
#' expert-defined weights.
#'
#' Ranges of numeric variables are taken from the training cases, so that
#' distances of query cases do not depend on each other.
#'
#' @references
#' Gower, J. C. (1971). A general coefficient of similarity and some of its
#' properties. Biometrics, 27(4), 857--871. \doi{10.2307/2528823}
#'
#' @examples
#' m <- GowerModel$new(Species ~ ., iris[-(1:3), ])
#' m$fit()
#' m$get_similar_cases(iris[1:3, ], k = 2)
#' m$predict_outcome(iris[1:3, ], k = 5)
#' @export
GowerModel <- R6Class(
  classname = "GowerModel",
  inherit = CBRBase,
  public = list(
    #' @field model the distance
    model = "gower",
    #' @field weights variable weights (named numeric)
    weights = NULL,
    #' @description
    #' Initialize a Gower distance model.
    #'
    #' @param formula Object of class formula or character, e.g.
    #'   \code{y ~ .} or \code{Surv(time, status) ~ x1 + x2}.
    #' @param data Training data of class data.frame
    #' @param weights variable weights, see \code{\link{gower_distance}}
    initialize = function(formula, data, weights = NULL) {
      super$initialize(formula, data)
      self$weights <- gower_weights(weights, self$variables)
    },
    #' @description
    #' Prints information of the initialized object
    print = function() {
      cat("Case-Based-Reasoning with the Gower distance\n")
      cat("---------------------------------------\n")
      cat("Endpoint  : ", paste(self$endpoint, collapse = ", "), "\n")
      cat("Variables : ", paste(self$variables, collapse = ", "), "\n")
      cat("Weights   : ", paste(format(self$weights), collapse = ", "), "\n")
      cat("Trained   : ", !is.null(self$model_fit), "\n")
    },
    #' @description
    #' "Fit" the model: prepare the case base and store the ranges of the
    #' numeric variables.
    fit = function() {
      train_tbl <- private$prepare_training()
      self$model_fit <- list(ranges = gower_ranges(train_tbl[, self$variables, drop = FALSE]))
      invisible(self)
    }
  ),
  private = list(
    explain_pair = function(query, case) {
      w <- self$weights
      d <- vapply(self$variables, function(v) {
        as.numeric(gower_variable(query[[v]], case[[v]], self$model_fit$ranges[[v]], v))
      }, numeric(1))
      contrib <- w * d / sum(w)
      res <- data.frame(variable = self$variables,
                        query_value = vapply(query[self$variables], function(v) as.character(v), ""),
                        case_value  = vapply(case[self$variables], function(v) as.character(v), ""),
                        weight = unname(w),
                        distance = unname(contrib),
                        share = if (sum(contrib) > 0) unname(contrib) / sum(contrib) else 0,
                        stringsAsFactors = FALSE)
      res <- res[order(-res$distance), , drop = FALSE]
      rownames(res) <- NULL
      res
    },
    get_distance_matrix = function(query = NULL) {
      private$ensure_fitted()
      x <- private$prepare_newdata(private$training_rows(), "training data")
      y <- if (is.null(query)) NULL else private$prepare_newdata(query)
      d <- gower_distance(x, y, weights = self$weights, ranges = self$model_fit$ranges)
      self$dist_matrix <- as.matrix(d)
    }
  )
)
