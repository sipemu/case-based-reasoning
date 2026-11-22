#' Distance calculation based on RandomForest Proximity or Depth
#'
#' @param x a data.frame
#' @param y a second data.frame
#' @param rfObject \code{ranger} object
#' @param method distance calculation method, Proximity (Default) or Depth.
#' @param proximity_type type of proximity for \code{method = "Proximity"},
#'   see \code{\link{proximity_distance}}.
#' @param threads number of threads to use. The previous RcppParallel thread
#'   setting is restored on exit.
#'
#' @return a \code{dist} or a matrix object with pairwise distance of
#' observations in x vs y (if not null)
#'
#' @examples
#' \donttest{
#' library(ranger)
#' # proximity pairwise distances
#' rf.fit <- ranger(Species ~ ., data = iris, num.trees = 500, write.forest = TRUE)
#' distance_random_forest(x = iris[, -5], rfObject = rf.fit, method = "Proximity", threads = 1)
#'
#' # depth distance for train versus test subset
#' set.seed(1234L)
#' learn <- sample(1:150, 100)
#' test <- (1:150)[-learn]
#' rf.fit <- ranger(Species ~ ., data = iris[learn, ], num.trees = 500, write.forest = TRUE)
#' distance_random_forest(x = iris[learn, -5], y = iris[test, -5], rfObject = rf.fit, method = "Depth")
#' }
#'
#' @export
distance_random_forest <- function(x, y = NULL, rfObject, method = "Proximity", threads = NULL,
                                   proximity_type = c("original", "oob", "rfgap")) {
  method <- match.arg(method, c("Proximity", "Depth"))
  proximity_type <- match.arg(proximity_type)
  validate_ranger(rfObject)

  # set number of threads for this call only
  if (!is.null(threads)) {
    old_threads <- Sys.getenv("RCPP_PARALLEL_NUM_THREADS", unset = NA)
    on.exit({
      if (is.na(old_threads)) {
        Sys.unsetenv("RCPP_PARALLEL_NUM_THREADS")
      } else {
        Sys.setenv(RCPP_PARALLEL_NUM_THREADS = old_threads)
      }
    }, add = TRUE)
    RcppParallel::setThreadOptions(numThreads = threads)
  }

  # Distance calculation
  if (method == "Proximity") {
    rf_dist <- proximity_distance(x = x, y = y, rfObject = rfObject, type = proximity_type)
  } else if (method == "Depth") {
    rf_dist <- depth_distance(x = x, y = y, rfObject = rfObject)
    rf_dist <- rf_dist / rfObject$num.trees
  }
  rf_dist
}



#' Get proximity matrix of an ranger object
#'
#' Random forest proximities between the observations in \code{x} and
#' \code{y}, converted to the distance \eqn{\sqrt{1 - p}} by default.
#'
#' Three types of proximity are available:
#' \describe{
#'   \item{\code{"original"}}{Breiman's proximity: the share of trees in which
#'     two observations share a terminal node. In-sample proximities are
#'     inflated because observations are counted in the trees they were
#'     trained on.}
#'   \item{\code{"oob"}}{Only trees in which the training observation (and,
#'     for in-sample queries, the query) is out-of-bag are used.}
#'   \item{\code{"rfgap"}}{RF-GAP proximities (Rhodes, Cutler & Moon, 2023):
#'     for query \eqn{q} and training observation \eqn{j},
#'     \eqn{p(q, j) = \frac{1}{|S_q|} \sum_{t \in S_q} c_j(t) 1[j \in
#'     leaf_t(q)] / |M_q(t)|}, where \eqn{S_q} are the trees in which \eqn{q}
#'     is out-of-bag (all trees for new data), \eqn{c_j(t)} is the in-bag count
#'     of \eqn{j} and \eqn{|M_q(t)|} the total in-bag count in \eqn{q}'s leaf.
#'     For each query the proximities sum to 1, and the proximity-weighted
#'     average of the training outcomes reproduces the forest's (out-of-bag)
#'     prediction for regression forests.}
#' }
#' \code{"oob"} and \code{"rfgap"} need the in-bag counts: fit the forest
#' with \code{keep.inbag = TRUE} and pass the forest's training data as
#' \code{x} (same rows, same order). If \code{y} is \code{NULL}, the training
#' data is also used as query (in-sample proximities).
#'
#' @param x a new dataset. For \code{type = "oob"} and \code{"rfgap"}: the
#'   training data of \code{rfObject}.
#' @param y a second new dataset (Default: NULL)
#' @param rfObject \code{ranger} object
#' @param as_dist Bool, convert proximity \eqn{p} to the distance
#'   \eqn{\sqrt{1 - p}}.
#' @param type proximity type: \code{"original"} (default), \code{"oob"} or
#'   \code{"rfgap"}.
#'
#' @return For \code{type = "original"}: a \code{dist} object (if \code{y} is
#' \code{NULL}) or a matrix with pairwise proximities (or distances, see
#' \code{as_dist}) of observations in x (rows) vs y (columns). For the other
#' types always a matrix; RF-GAP proximities are not symmetric.
#'
#' @references
#' Rhodes, J. S., Cutler, A. and Moon, K. R. (2023). Geometry- and
#' Accuracy-Preserving Random Forest Proximities. IEEE Transactions on Pattern
#' Analysis and Machine Intelligence, 45(9), 10947--10959.
#' \doi{10.1109/TPAMI.2023.3263774}
#'
#' @examples
#' \donttest{
#' library(ranger)
#' rf <- ranger(Species ~ ., data = iris, num.trees = 5, write.forest = TRUE)
#' proximity_distance(x = iris[, -5], rfObject = rf)
#'
#' set.seed(1234L)
#' learn <- sample(1:150, 100)
#' test <- (1:150)[-learn]
#' rf <- ranger(Species ~ ., data = iris[learn, ], num.trees = 500,
#'              write.forest = TRUE, keep.inbag = TRUE)
#' proximity_distance(x = iris[learn, -5], y = iris[test, -5], rfObject = rf)
#' proximity_distance(x = iris[learn, -5], y = iris[test, -5], rfObject = rf,
#'                    type = "rfgap")
#' }
#' @export
proximity_distance <- function(x, y = NULL, rfObject, as_dist = TRUE,
                               type = c("original", "oob", "rfgap")) {
  type <- match.arg(type)
  xNodes <- terminal_nodes(x, rfObject)
  if (type == "original") {
    if (is.null(y)) {
      d <- cpp_proximityMatrix(xNodes)
      n <- nrow(x)
      # convert to dist object
      rf_dist <- as_dist_object(d, n, "RFProximity")
    } else {
      yNodes <- terminal_nodes(y, rfObject)
      rf_dist <- cpp_proximityMatrixRangerXY(xNodes, yNodes)
    }
  } else {
    if (is.null(rfObject$inbag.counts)) {
      stop("Proximity type '", type, "' needs in-bag counts: ",
           "fit the forest with keep.inbag = TRUE.")
    }
    inbag <- do.call(cbind, rfObject$inbag.counts)
    if (nrow(inbag) != nrow(xNodes)) {
      stop("For proximity type '", type, "', 'x' must be the training data of ",
           "the forest (", nrow(inbag), " rows).")
    }
    storage.mode(inbag) <- "double"
    if (is.null(y)) {
      yNodes <- xNodes
      yInbag <- inbag
    } else {
      yNodes <- terminal_nodes(y, rfObject)
      yInbag <- matrix(numeric(0), 0, 0)
    }
    rf_dist <- cpp_oobProximity(xNodes, yNodes, inbag, yInbag,
                                type = if (type == "oob") 0L else 1L)
  }

  # to distance
  # proximities lie in [0, 1], independent of the observations in x and y
  if (as_dist) {
    rf_dist <- sqrt(pmax(1 - rf_dist, 0))
  }
  rf_dist
}


#' @title Depth Distance
#'
#' @description This function returns for each observation the pairwise sum of edges
#' between the corresponding terminal nodes over each tree in the random forest.
#'
#' @param x A data.frame with the same columns as in the training data of the RandomForest model
#' @param y A data.frame with the same columns as in the training data of the RandomForest model
#' @param rfObject \code{ranger} object
#'
#' @examples
#' \donttest{
#' library(ranger)
#' rf <- ranger(Species ~ ., data = iris, num.trees = 5, write.forest = TRUE)
#' depth_distance(x = iris[, -5], rfObject = rf)
#' }
#'
#' @export
depth_distance <- function(x, y = NULL, rfObject) {
  xNodes <- terminal_nodes(x, rfObject)
  rfTrees <- ranger_forests_to_matrix(rfObject)
  if (is.null(y)) {
    d <- cpp_depthMatrix(xNodes, rfTrees)
    n <- nrow(x)
    # convert to dist object
    rf_dist <- as_dist_object(d, n, "RFDepth")
  } else {
    yNodes <- terminal_nodes(y, rfObject)
    rf_dist <- cpp_depthMatrixRangerXY(xNodes, yNodes, rfTrees)
  }
  rf_dist
}


#' @title Number of Edges between Terminal Nodes
#'
#' @description first two columns are terminal node IDs; If an ID pair do not
#' appear in a tree -1 is inserted
#'
#' @param rfObject \code{ranger} object
#'
#' @return a \code{matrix} object with pairwise terminal node edge length
#'
#' @examples
#' \donttest{
#' library(ranger)
#' rf.fit <- ranger(Species ~ ., data = iris, num.trees = 5, write.forest = TRUE)
#' edges_between_terminal_nodes(rf.fit)
#' }
#'
#' @export
edges_between_terminal_nodes <- function(rfObject) {
  validate_ranger(rfObject)
  rfTrees <- ranger_forests_to_matrix(rfObject)
  cpp_TerminalNodeDistance(rfTrees)
}


#' Weighted Distance calculation
#'
#' Computes \eqn{d(x_i, y_j) = \sum_k |w_k (x_{ik} - y_{jk})|}.
#'
#' @param x a numeric matrix
#' @param y a second numeric matrix with the same columns as \code{x}
#'   (default: \code{NULL}, pairwise distances within \code{x})
#' @param weights a vector of weights, one per column (default: all 1)
#'
#' @return a \code{dist} object (if \code{y} is \code{NULL}) or a
#'   \code{nrow(x)} x \code{nrow(y)} matrix
#'
#' @examples
#' x <- as.matrix(iris[1:5, 1:4])
#' weighted_distance(x)
#' weighted_distance(x, as.matrix(iris[6:7, 1:4]), weights = c(1, 1, 2, 2))
#'
#' @export
weighted_distance <- function(x, y = NULL, weights = NULL) {
  x <- as.matrix(x)
  if (is.null(weights)) {
    weights <- rep(1, ncol(x))
  }
  if (length(weights) != ncol(x)) {
    stop("'weights' must have one element per column of 'x' (", ncol(x), ").")
  }
  if (!is.null(y)) {
    y <- as.matrix(y)
    if (ncol(y) != ncol(x)) {
      stop("'x' and 'y' must have the same number of columns.")
    }
  }
  if (is.null(y)) {
    d <- cpp_weightedDistance(x, weights)
    return(as_dist_object(d, nrow(x), "weightedDistance"))
  } else {
    return(cpp_weightedDistanceXY(x, y, weights))
  }
}
