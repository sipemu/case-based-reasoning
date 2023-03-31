#' Get the terminal node id of a RandomForest Object
#' 
#' Extracts for each observation and for each tree in the forest the terminal 
#' node id. The index of terminal nodes are starting with 1, e.g., the root node has id 1
#'
#' @param x a data.frame
#' @param rfObject \code{ranger} object
#' 
#' @return Matrix with terminal node IDs for all observations in x (rows) and
#'         trees (columns)
#'         
#' @examples
#' library(ranger)
#' rf.fit <- ranger(Species ~ ., data = iris, num.trees = 5, write.forest = TRUE)
#' dfNodes <- terminalNodes(iris[, -5], rf.fit)
#' 
#' @export
terminalNodes <- function(x, rfObject) {
  testthat::expect_is(rfObject, "ranger")
  testthat::expect_false(object = is.null(rfObject$forest), 
                         info   = "Ranger object does not contain a forest.")
  x <- as.matrix(x)
  res=sapply(1:rfObject$num.trees, function(tree) {
    cpp_terminalNodeID(x = x, 
                       childNodes1 = rfObject$forest$child.nodeIDs[[tree]][[1]], 
                       childNodes2 = rfObject$forest$child.nodeIDs[[tree]][[2]], 
                       splitValues = as.double(rfObject$forest$split.values[[tree]]),
                       splitVarIds = rfObject$forest$split.varIDs[[tree]])
  }, simplify = F)
  res <- do.call(cbind, res)
  # switch from 0-index to 1-index
  as.matrix(res) + 1
}


#' @title Forest2Matrix
#' 
#' @description Transform trees of a \code{ranger}-object to a matrix
#' 
#' @param rfObject \code{ranger} object
#' 
#' @return a \code{matrix} object with 
#' Column 1: tree ID
#' Column 2: node ID
#' Column 3: child node ID 1
#' Column 4: child node ID 2
#'
#' @examples
#' library(ranger)
#' rf.fit <- ranger(Species ~ ., data = iris, num.trees = 5, write.forest = TRUE)
#' forestMat <- forestToMatrix(rf.fit)
#' 
#' @export
ranger_forests_to_matrix <- function(rfObject) {
  res <- sapply(1:rfObject$num.trees, function(t) {
    len <- length(rfObject$forest$child.nodeIDs[[t]][[1]])
    data.frame(t   = rep(t, len), 
               n   = seq_len(len),
               id1 = rfObject$forest$child.nodeIDs[[t]][[1]],
               id2 = rfObject$forest$child.nodeIDs[[t]][[2]],
               split_id = rfObject$forest$split.varIDs[[t]])
  }, simplify = F)
  res <- do.call(rbind, res)
  res %>% 
    as.matrix()
}


#' Converts a distance vector into an object of class \code{dist}
#' 
#' @param x data vector
#' @param n length of x
#' @param method method description
#' 
#' @export
asDistObject <- function(x, n, method) {
  structure(.Data  = x,
            Size   = n,
            Labels = 1:n,
            Diag   = F,
            Upper  = F,
            method = method,
            class  = "dist")
}


#' call a function by character strings
call_function = function(func_list) {
  func_name <- func_list$func
  func_namespace <- func_list$namespace
  func_args <- func_list$args
  func_to_call <- get(func_name, envir = as.environment(func_namespace))
  pryr::do_call(func_to_call, func_args)
}