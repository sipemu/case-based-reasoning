#' Root class for common functionality of this package
#'
#' @keywords datapreparation
CBRBase <- R6Class("CBRBase",
                   public = list(
                     #' @field model the statistical model
                     model     = '',
                     #' @field data training data
                     data      = NULL,
                     #' @field model_fit trained object
                     model_fit = NULL,
                     #' @field formula Object of class formula or character describing the model fit
                     formula   = NULL,
                     #' @field terms terms of the formula (term labels, e.g. \code{"rcs(age, 3)"})
                     terms     = NULL,
                     #' @field variables variables used by the terms of the formula
                     variables = NULL,
                     #' @field endpoint Target variable
                     endpoint  = NULL,
                     #' @field dist_matrix A matrix with distances
                     dist_matrix   = NULL,
                     #' @field order_matrix A matrix with the order indices for similar cases search
                     order_matrix  = NULL,
                     #' @description
                     #' Initialize object for searching similar cases
                     #'
                     #' @param formula Object of class formula or character describing the model fit
                     #' @param data Training data of class data.frame
                     initialize = function(formula, data) {
                       formula <- as.formula(formula)
                       if (!inherits(formula, "formula")) {
                         stop("Invalid formula: expected a formula object.")
                       }
                       self$formula <- formula
                       tt <- terms(formula, data = data)
                       self$terms <- labels(tt)
                       self$endpoint <- if (length(formula) == 3) all.vars(formula[[2]]) else character(0)
                       self$variables <- setdiff(all.vars(stats::delete.response(tt)), self$endpoint)
                       # validate that the variables of the formula exist in data
                       missing_vars <- setdiff(c(self$endpoint, self$variables), names(data))
                       if (length(missing_vars) > 0) {
                         stop("Variables not found in data: ", paste(missing_vars, collapse = ", "))
                       }
                       self$data <- data
                     },
                     #' @description
                     #' Fit the Model
                     fit = function() {
                       # virtual function
                     },
                     #' @description
                     #' Calculates the distance matrix
                     #'
                     #' @param query Query data of class data.frame
                     calc_distance_matrix = function(query = NULL) {
                       private$get_distance_matrix(query = query)
                     },
                     #' @description
                     #' Extracts similar cases
                     #'
                     #' @param query Query data of class data.frame
                     #' @param k number of similar cases
                     #' @param add_distance Add distance to result data.frame
                     #' @param merge Add query data to matched cases data.frame
                     #' @param exclude_self Exclude training cases whose row name equals
                     #'   the query's row name. Use this when the query rows are taken
                     #'   from the training data, so that a case is not returned as its
                     #'   own nearest neighbour.
                     get_similar_cases = function(query, k = 1, add_distance = TRUE, merge = FALSE,
                                                  exclude_self = FALSE) {
                       if (missing(query)) {
                         stop("'query' is required. Pass the data for which you want to find similar cases.")
                       }
                       if (!is.numeric(k) || length(k) != 1 || is.na(k) || k != round(k)) {
                         stop("'k' must be a single whole number.")
                       }
                       if (k < 1) {
                         stop("'k' must be >= 1.")
                       }
                       k <- as.integer(k)
                       private$ensure_fitted()
                       n_avail <- length(private$train_idx) - as.integer(isTRUE(exclude_self))
                       if (k > n_avail) {
                         stop("'k' (", k, ") is larger than the number of available training cases (",
                              n_avail, ").")
                       }

                       # calculate distance matrix
                       distance_matrix <- as.matrix(private$get_distance_matrix(query = query))
                       if (isTRUE(exclude_self)) {
                         self_match <- outer(rownames(private$training_rows()), rownames(query), "==")
                         distance_matrix[self_match] <- Inf
                       }

                       # calculate distance and order of cases based on distance calculation
                       similar_cases_tbl <- private$extract_similar_cases(
                         x              = private$training_rows(),
                         query          = query,
                         distanceMatrix = distance_matrix,
                         k              = k,
                         add_distance   = add_distance,
                         merge          = merge
                       )
                       similar_cases_tbl
                     }
                   ),
                   active = list(
                     #' @field endPoint Deprecated: use \code{endpoint} instead.
                     endPoint = function(value) {
                       if (missing(value)) {
                         .Deprecated("endpoint", old = "endPoint")
                         self$endpoint
                       } else {
                         .Deprecated("endpoint", old = "endPoint")
                         self$endpoint <- value
                       }
                     },
                     #' @field distMat Deprecated: use \code{dist_matrix} instead.
                     distMat = function(value) {
                       if (missing(value)) {
                         .Deprecated("dist_matrix", old = "distMat")
                         self$dist_matrix
                       } else {
                         .Deprecated("dist_matrix", old = "distMat")
                         self$dist_matrix <- value
                       }
                     },
                     #' @field orderMat Deprecated: use \code{order_matrix} instead.
                     orderMat = function(value) {
                       if (missing(value)) {
                         .Deprecated("order_matrix", old = "orderMat")
                         self$order_matrix
                       } else {
                         .Deprecated("order_matrix", old = "orderMat")
                         self$order_matrix <- value
                       }
                     }
                   ),
                   private = list(
                     # row indices (into self$data) of the cases used for fitting
                     train_idx = NULL,
                     # levels of factor terms in the fitted training data
                     factor_levels = NULL,
                     ensure_fitted = function() {
                       if (is.null(private$train_idx)) {
                         stop("Model not trained: call $fit() first.")
                       }
                       invisible(TRUE)
                     },
                     # training cases (all columns) that were used for fitting
                     training_rows = function() {
                       self$data[private$train_idx, , drop = FALSE]
                     },
                     # select model variables, drop incomplete cases, convert characters
                     # to factors and remember the factor levels for aligning queries
                     prepare_training = function() {
                       x <- self$data[, c(self$endpoint, self$variables), drop = FALSE]
                       keep <- stats::complete.cases(x)
                       if (!any(keep)) {
                         stop("Learning data is empty after NA elimination.")
                       }
                       if (!all(keep)) {
                         warning("Dropped cases with missing values: ", sum(!keep))
                       }
                       x <- x[keep, , drop = FALSE]
                       x <- private$check_factor(x)
                       x <- droplevels(x)
                       private$train_idx <- which(keep)
                       is_fct <- vapply(self$variables, function(v) is.factor(x[[v]]), logical(1))
                       private$factor_levels <- lapply(x[self$variables[is_fct]], levels)
                       x
                     },
                     # align new data (query or training rows) to the fitted training data:
                     # factor levels are matched by name, numeric variables must stay numeric
                     prepare_newdata = function(df, what = "query") {
                       missing_vars <- setdiff(self$variables, names(df))
                       if (length(missing_vars) > 0) {
                         stop("Variables not found in ", what, ": ", paste(missing_vars, collapse = ", "))
                       }
                       df <- df[, self$variables, drop = FALSE]
                       for (v in self$variables) {
                         lev <- private$factor_levels[[v]]
                         if (!is.null(lev)) {
                           val <- as.character(df[[v]])
                           unseen <- setdiff(unique(val[!is.na(val)]), lev)
                           if (length(unseen) > 0) {
                             stop("Unknown level(s) of '", v, "' in ", what, ": ",
                                  paste(unseen, collapse = ", "))
                           }
                           df[[v]] <- factor(val, levels = lev)
                         } else if (is.logical(df[[v]])) {
                           df[[v]] <- as.numeric(df[[v]])
                         } else if (!is.numeric(df[[v]])) {
                           stop("Variable '", v, "' is numeric in the training data but '",
                                class(df[[v]])[1], "' in ", what, ".")
                         }
                       }
                       incomplete <- which(!stats::complete.cases(df))
                       if (length(incomplete) > 0) {
                         stop("Missing values in ", what, " (rows: ",
                              paste(utils::head(incomplete, 10), collapse = ", "),
                              if (length(incomplete) > 10) ", ..." else "", ").")
                       }
                       df
                     },
                     # transform character variables to factor
                     check_factor = function(x) {
                       trf <- c()
                       for (var in self$variables) {
                         if (is.character(x[[var]])) {
                           trf <- c(trf, var)
                           x[[var]] <- factor(x[[var]])
                         }
                       }
                       if (length(trf) > 0) {
                         warning(paste0("Following variables are transformed to class factor: ", paste(trf, collapse = ", ")))
                       }
                       return(x)
                     },
                     get_distance_matrix = function(query = NULL) {
                       # virtual function
                     },
                     extract_similar_cases = function(x, query, distanceMatrix, k = 1, add_distance = TRUE, merge = TRUE) {
                       m <- ncol(distanceMatrix)

                       # get closest elements
                       orderedMatrix <- cpp_orderMatrix(
                         distanceMatrix,
                         sortDirection = 0,
                         k             = k
                       )

                       df_list <- lapply(seq_len(m), function(colID) {
                         rowIDs <- orderedMatrix[, colID]
                         dtTmp <- x[rowIDs, , drop = FALSE]
                         if (add_distance) {
                           dtTmp$scDist <- distanceMatrix[rowIDs, colID]
                         }
                         dtTmp
                       })
                       df_sc <- do.call(rbind, df_list)

                       # mark similar cases: 1:n ids
                       df_sc$caseId <- rep(seq_len(k), m)

                       if (merge) {
                         df_sc <- private$merge_matched_data(
                           query = query,
                           df_sc = df_sc,
                           k     = k
                         )
                       }
                       df_sc
                     },
                     merge_matched_data = function(query, df_sc, k) {
                       # scCaseId: finally sort data.frame such that matched cases are close
                       query$scCaseId <- seq_len(nrow(query))
                       query$group <- "Query"
                       query$scDist <- 0.0
                       query$caseId <- 0L
                       matchedData <- df_sc
                       matchedData$scCaseId <- rep(seq_len(nrow(query)), each = k)
                       matchedData$group <- "Matched"
                       # the query may lack columns of the training data (e.g. the endpoint)
                       for (col in setdiff(names(matchedData), names(query))) {
                         query[[col]] <- NA
                       }
                       query <- query[, names(matchedData), drop = FALSE]
                       result <- rbind(matchedData, query)
                       result[order(result$scCaseId, result$caseId), , drop = FALSE]
                     }
                   )
)
