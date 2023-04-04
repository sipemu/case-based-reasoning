#' Root class for common functionality of this package
#' 
#' @keywords data-preparation
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
                     #' @field terms terms of the formula
                     terms     = NULL,
                     #' @field endPoint Target variable
                     endPoint  = NULL,
                     #' @field distMat A matrix with distances
                     distMat   = NULL,
                     #' @field orderMat A matrix with the order indices for similar cases search
                     orderMat  = NULL,
                     #' @description 
                     #' Initialize object for searching similar cases
                     #'
                     #' @param formula Object of class formula or character describing the model fit
                     #' @param data 
                     initialize = function(formula, data) {
                       formula <- as.formula(formula)
                       testthat::expect_is(formula, "formula", "Invalid formula.")
                       self$formula <- formula
                       self$terms <- labels(terms(formula, data=data))
                       self$endPoint <- setdiff(all.vars(formula), '.')
                       self$endPoint <- setdiff(self$endPoint, self$terms)
                       self$data <- data.table::as.data.table(data)
                     },
                     #' @description 
                     #' Fit the Model
                     #' 
                     #' @param x Training data of class data.frame
                     fit = function() {
                       # virtual function
                     },
                     #' @description 
                     #' Calculates the distance matrix
                     #' 
                     #' @param x Training data of class data.frame
                     #' @param query Query data of class data.frame
                     calc_distance_matrix = function(query = NULL) {
                       private$get_distance_matrix(query = query)
                     },
                     #' @description 
                     #' Extracts similar cases
                     #' 
                     #' @param query Query data of class data.frame
                     #' @param k number of similar cases
                     #' @param addDistance Add distance to result data.frame
                     #' @param merge Add query data to matched cases data.frame
                     get_similar_cases = function(query, k = 1, addDistance = T, merge = F) { 
                       # check nCases input 
                       testthat::expect_is(k, "numeric")
                       testthat::expect_true(k >= 0, "numeric")
                       # catch floating numbers
                       k <- as.integer(k)
                       
                       if (missing(query)) {
                         cat("No query data.\n") 
                         query <- data.table::copy(self$data)
                       } else {
                         query <- data.table::as.data.table(query)
                       }
                       
                       start <- Sys.time()
                       cat("Start caclulating similar cases...\n")
                       
                       # calculate distance matrix
                       distance_matrix <- private$get_distance_matrix(query = as.data.table(query))
                       
                       # calculate distance and order of cases based on distance calculation
                       self$data |> 
                         private$extract_similar_cases(query          = query,
                                                       distanceMatrix = distance_matrix, 
                                                       k              = k, 
                                                       addDistance    = addDistance, 
                                                       merge          = merge) -> similar_cases_tbl
                       end <- Sys.time()
                       duration <- round(as.numeric(end - start), 2)
                       cat(paste0("Similar cases calculation finished in: ", duration, " seconds.\n"))
                       similar_cases_tbl
                     }
                   ),
                   private = list(
                     check_data = function(x, isLearning=T) {
                       if (is(x, "data.table")) {
                         x <- data.table::copy(x)
                       } else {
                         x <- data.table::copy(data.table::as.data.table(x))
                       }
                       # drop cases with missing values in the relevant variables
                       x <- private$drop_missing(x, isLearning)
                       if (nrow(x) == 0) {
                         if (isLearning) {
                           stop("Error: Learning data is empty after NA elimination.")
                         } else {
                           stop("Error: Query is empty after NA elimination.")
                         }
                       }
                       # check character variables: need factors
                       x <- private$check_factor(x)
                       # check levels of factor variables
                       # more tests
                       return(x)
                     },
                     drop_missing = function(df, isLearning=F) {
                       df <- df |> 
                         dplyr::select(c(self$endPoint, self$terms))
                       rs <- rowSums(is.na(df))
                       idDrop <- which(rs > 0)
                       cat(paste0("Dropped cases with missing values: ", length(idDrop), "\n"))
                       if (length(idDrop) > 0)
                         df <- df[-idDrop, ]
                       return(df)
                     },
                     # transform character variables to factor
                     check_factor = function(x) {
                       trf <- c()
                       for (var in self$terms) {
                         if (is.character(x[[var]])) {
                           trf <- c(trf, var)
                           x[[var]] <- factor(x[[var]])
                         }
                       }
                       if (length(trf) > 0) {
                         cat(paste0("Following variables are transformed to class factor: ", paste(trf, collapse=", "), "\n"))
                       }
                       return(x)
                     },
                     # transforms data to integer representation;
                     # necessary for c++ functions
                     to_int = function(x) {
                       if (is.null(x))
                         return(x)
                       
                       for (i in 1:ncol(x)) {
                         if (!is.numeric(x[[i]])) {
                           x[[i]] <- as.numeric(as.factor(x[[i]]))
                         }
                       }
                       return(x)
                     },
                     get_distance_matrix=function(x, query = NULL) {
                       # virtual function
                     },
                     extract_similar_cases=function(x, query, distanceMatrix, k = 1, addDistance = T, merge = T) {
                       m <- ncol(distanceMatrix)
                       
                       # get closest elements
                       distanceMatrix |> 
                         as.matrix() |> 
                         cpp_orderMatrix(sortDirection = 0,
                                         k             = k) -> orderedMatrix
                       
                       colID <- 1:ncol(orderedMatrix)
                       orderedMatrix |> 
                         tibble::as_tibble() |> 
                         purrr::map2(.y = colID, .f = function(rowIDs, colID, x, distanceMatrix) {
                           dtTmp <- x[rowIDs, ]
                           if (addDistance) {
                             dtTmp$scDist <- distanceMatrix[rowIDs, colID]
                           }
                           dtTmp
                         }, x = x, distanceMatrix = distanceMatrix) -> df_sc
                       df_sc <- data.table::rbindlist(df_sc)
                       
                       # mark similar cases: 1:n ids
                       df_sc$caseId <- rep(1:k, m)
                       
                       if (merge) {
                         query |> 
                           private$merge_matched_data(df_sc = df_sc, 
                                                      k     = k) -> df_sc
                       }
                       df_sc
                     },
                     merge_matched_data = function(query, df_sc, k) {
                       # scCaseId: finally sort data.frame such that matched cases are close
                       query$scCaseId <- 1:nrow(query)
                       query$group <- "Query"
                       query$scDist <- 0.0
                       query$caseId <- 0
                       matchedData <- df_sc
                       matchedData$scCaseId <- rep(1:nrow(query), each = k)
                       matchedData$group <- "Matched"
                       query |> 
                         dplyr::select(names(matchedData)) -> query
                       rbind(query, matchedData) |> 
                         dplyr::arrange(scCaseId)
                     }
                   )
)