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
                     },
                     #' @description
                     #' Predict survival curves from the \code{k} most similar
                     #' training cases: a Kaplan-Meier estimate over the retrieved
                     #' cases of each query (Lowsky et al., 2013). Only for survival
                     #' endpoints (\code{Surv(time, status)}).
                     #'
                     #' @param query Query data of class data.frame
                     #' @param k number of similar cases
                     #' @param times time points; default: the event times of the
                     #'   training data
                     #' @param weighted If \code{TRUE}, cases are weighted with a
                     #'   tricube kernel of their distance to the query.
                     #' @return A matrix of survival probabilities with one row per
                     #'   query and one column per time point (attribute \code{times}).
                     #' @references
                     #' Lowsky, D. J. et al. (2013). A K-nearest neighbors survival
                     #' probability prediction method. Statistics in Medicine, 32(12),
                     #' 2062--2069. \doi{10.1002/sim.5673}
                     predict_survival = function(query, k = 10, times = NULL, weighted = FALSE) {
                       outcome <- private$survival_outcome()
                       k <- private$check_k(k)
                       if (is.null(times)) {
                         times <- sort(unique(outcome$time[outcome$status == 1]))
                       }
                       dist <- as.matrix(private$get_distance_matrix(query = query))
                       surv <- predict_survival_cases(dist, outcome$time, outcome$status,
                                                      k, times, weighted)
                       attr(surv, "times") <- times
                       surv
                     },
                     #' @description
                     #' Evaluate survival predictions from retrieved cases on test
                     #' data: Uno's concordance index and the IPCW (integrated)
                     #' Brier score. Use it to choose \code{k} and the distance
                     #' method on held-out data.
                     #'
                     #' @param test Test data with the endpoint columns
                     #' @param k number of similar cases
                     #' @param times time points for the Brier score; default: 20
                     #'   points between the 10\% and 90\% quantile of the training
                     #'   event times
                     #' @param tau time horizon for the concordance index (risk score
                     #'   \eqn{1 - S(\tau)}); default: the largest of \code{times}
                     #' @param weighted passed to \code{predict_survival()}
                     #' @return A list with \code{c_index} (Uno's C), \code{ibs}
                     #'   (integrated Brier score) and \code{brier} (data.frame with
                     #'   the Brier score at each time).
                     #' @references
                     #' Uno, H. et al. (2011). On the C-statistics for evaluating
                     #' overall adequacy of risk prediction procedures with censored
                     #' survival data. Statistics in Medicine, 30(10), 1105--1117.
                     #' \doi{10.1002/sim.4154}
                     #'
                     #' Graf, E. et al. (1999). Assessment and comparison of
                     #' prognostic classification schemes for survival data.
                     #' Statistics in Medicine, 18(17-18), 2529--2545.
                     evaluate_survival = function(test, k = 10, times = NULL, tau = NULL,
                                                  weighted = FALSE) {
                       outcome <- private$survival_outcome()
                       missing_cols <- setdiff(self$endpoint, names(test))
                       if (length(missing_cols) > 0) {
                         stop("Endpoint columns not found in test data: ",
                              paste(missing_cols, collapse = ", "))
                       }
                       test_time <- test[[self$endpoint[1]]]
                       test_status <- as.numeric(test[[self$endpoint[2]]])
                       if (is.null(times)) {
                         ev <- outcome$time[outcome$status == 1]
                         times <- unique(stats::quantile(ev, seq(0.1, 0.9, length.out = 20),
                                                         names = FALSE))
                       }
                       times <- sort(times)
                       if (is.null(tau)) tau <- max(times)
                       surv <- self$predict_survival(test, k = k, times = sort(unique(c(times, tau))),
                                                     weighted = weighted)
                       all_times <- attr(surv, "times")
                       s_tau <- surv[, match(tau, all_times)]
                       cc <- survival::concordance(
                         survival::Surv(test_time, test_status) ~ s_tau,
                         timewt = "n/G2", ymax = tau
                       )
                       bs <- brier_ipcw(surv[, match(times, all_times), drop = FALSE],
                                        test_time, test_status, times,
                                        outcome$time, outcome$status)
                       list(c_index = unname(cc$concordance),
                            ibs     = integrate_mean(times, bs),
                            brier   = data.frame(time = times, brier = bs))
                     },
                     #' @description
                     #' Counterfactual cases: the nearest training cases whose
                     #' outcome differs from the query's outcome ("native
                     #' counterfactuals", Keane & Smyth, 2020).
                     #'
                     #' The query's outcome is taken from its endpoint columns if
                     #' present, otherwise it is predicted from its \code{k_outcome}
                     #' most similar cases (majority class, mean, or majority
                     #' event status). A training case is a counterfactual if
                     #' \itemize{
                     #'   \item classification endpoint: its class differs;
                     #'   \item numeric endpoint: its outcome differs by at least
                     #'     \code{min_diff} (default: standard deviation of the
                     #'     training outcome);
                     #'   \item survival endpoint: its event status at
                     #'     \code{horizon} differs (event before \code{horizon} vs.
                     #'     followed beyond \code{horizon}; cases censored before
                     #'     \code{horizon} are not used).
                     #' }
                     #'
                     #' @param query Query data of class data.frame
                     #' @param k number of counterfactual cases per query
                     #' @param horizon time horizon for survival endpoints
                     #'   (default: median training event time)
                     #' @param min_diff minimum outcome difference for numeric
                     #'   endpoints
                     #' @param k_outcome number of similar cases used to predict the
                     #'   query's outcome if it is not given
                     #' @return A data.frame like \code{get_similar_cases()} with the
                     #'   additional column \code{queryOutcome}.
                     #' @references
                     #' Keane, M. T. and Smyth, B. (2020). Good Counterfactuals and
                     #' Where to Find Them: A Case-Based Technique for Generating
                     #' Counterfactuals for Explainable AI. ICCBR 2020, LNCS 12311,
                     #' 163--178. \doi{10.1007/978-3-030-58342-2_11}
                     get_counterfactual_cases = function(query, k = 1, horizon = NULL,
                                                         min_diff = NULL, k_outcome = 10) {
                       k <- private$check_k(k)
                       k_outcome <- min(private$check_k(k_outcome), length(private$train_idx))
                       train <- private$training_rows()
                       if (length(self$endpoint) == 2 && is.null(horizon)) {
                         ev <- train[[self$endpoint[1]]][as.numeric(train[[self$endpoint[2]]]) == 1]
                         horizon <- stats::median(ev)
                       }
                       y_train <- outcome_values(train, self$endpoint, horizon)
                       if (y_train$type == "numeric" && is.null(min_diff)) {
                         min_diff <- stats::sd(y_train$value)
                       }

                       dist <- as.matrix(private$get_distance_matrix(query = query))

                       # outcome of the query: observed or predicted from similar cases
                       if (all(self$endpoint %in% names(query)) &&
                           !anyNA(query[, self$endpoint, drop = FALSE])) {
                         y_query <- outcome_values(query, self$endpoint, horizon)$value
                       } else {
                         nn <- cpp_orderMatrix(dist, sortDirection = 0, k = k_outcome)
                         y_query <- vapply(seq_len(ncol(dist)), function(q) {
                           v <- y_train$value[nn[, q]]
                           if (y_train$type == "numeric") as.character(mean(v)) else majority(v)
                         }, character(1))
                         if (y_train$type == "numeric") y_query <- as.numeric(y_query)
                       }

                       # mask cases that are not counterfactuals
                       for (q in seq_len(ncol(dist))) {
                         is_cf <- if (y_train$type == "numeric") {
                           abs(y_train$value - y_query[q]) >= min_diff
                         } else {
                           !is.na(y_train$value) & y_train$value != y_query[q]
                         }
                         is_cf[is.na(is_cf)] <- FALSE
                         if (sum(is_cf) < k) {
                           stop("Only ", sum(is_cf), " counterfactual case(s) available for query ", q,
                                ", but k = ", k, ".")
                         }
                         dist[!is_cf, q] <- Inf
                       }
                       res <- private$extract_similar_cases(
                         x = train, query = query, distanceMatrix = dist, k = k,
                         add_distance = TRUE, merge = FALSE
                       )
                       res$queryOutcome <- rep(y_query, each = k)
                       res
                     },
                     #' @description
                     #' Explain why a training case is similar to a query.
                     #' For regression models: the contribution of each term to the
                     #' linear predictor of query and case, and its share of the
                     #' distance. For random forests: in the trees where query and
                     #' case end in different terminal nodes, the split variable at
                     #' which their paths diverge.
                     #'
                     #' @param query One query case (data.frame with one row)
                     #' @param case One case (data.frame with one row), e.g. a row
                     #'   returned by \code{get_similar_cases()}
                     #' @return A data.frame with one row per term (regression) or
                     #'   variable (random forest).
                     explain_match = function(query, case) {
                       private$ensure_fitted()
                       if (nrow(query) != 1 || nrow(case) != 1) {
                         stop("'query' and 'case' must have exactly one row each.")
                       }
                       private$explain_pair(private$prepare_newdata(query),
                                            private$prepare_newdata(case, "case"))
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
                     check_k = function(k) {
                       if (!is.numeric(k) || length(k) != 1 || is.na(k) || k != round(k) || k < 1) {
                         stop("'k' must be a single whole number >= 1.")
                       }
                       private$ensure_fitted()
                       if (k > length(private$train_idx)) {
                         stop("'k' (", k, ") is larger than the number of available training cases (",
                              length(private$train_idx), ").")
                       }
                       as.integer(k)
                     },
                     # time and status of the training cases for survival endpoints
                     survival_outcome = function() {
                       if (length(self$endpoint) != 2) {
                         stop("Survival prediction needs a survival endpoint, e.g. Surv(time, status) ~ ...")
                       }
                       private$ensure_fitted()
                       x <- private$training_rows()
                       status <- x[[self$endpoint[2]]]
                       if (is.logical(status)) status <- as.numeric(status)
                       if (!is.numeric(status) || !all(status %in% c(0, 1))) {
                         stop("The status variable '", self$endpoint[2], "' must be 0/1 or logical.")
                       }
                       list(time = x[[self$endpoint[1]]], status = status)
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
                     explain_pair = function(query, case) {
                       stop("explain_match() is not implemented for this model.")
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
