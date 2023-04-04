#' Root class for Regression Models, e.g., CPH, logistic, and linear regression
#' 
#' @keywords data-preparation
RegressionModel <- R6Class(
  classname = "RegressionModel",
  inherit = CBRBase,
  public=list(
    #' @field model_params rms arguments
    model_params = list(x = T, y = T),
    #' @field weights Weights for distance calculation
    weights     = NULL,
    #' @description 
    #' Prints information of the initialized object
    print = function() {
      cat("Case-Based-Reasoning based Regression Coefficients\n")
      cat("---------------------------------------\n")
      cat("Model     : ", paste(self$model, collapse = ", "), '\n')
      cat("Endpoint  : ", paste(self$endPoint, collapse = ", "), '\n')
      cat("Variables : ", paste(self$terms, collapse = ", "), '\n')
      cat("Trained   : ", ifelse(is.null(self$weights), FALSE, TRUE), '\n')
    },
    #' @description  
    #' Fast backward variable selection with penalization
    #' 
    #' @param x Training data of class data.frame
    variable_selection = function(x) {
      x |>
        dplyr::select(c(self$endPoint, self$terms)) -> x
      x <- private$check_data(x)
      
      # Timing
      start <- Sys.time()
      cat("Start learning...\n")
      #  datadist scoping
      regression_data <<- rms::datadist(x)
      options(datadist="regression_data")
      
      # train regression model
      func <- get(self$model, envir = as.environment('package:rms'))
      params <- self$model_params
      params$data <- x
      params$formula <- self$formula
      self$model_fit <- pryr::do_call(func, params)
      
      # Variable Selection
      vars <- rms::fastbw(fit = self$model_fit, type = "i")
      cat(paste0("Initial variable set: ", paste(c(self$endPoint, self$terms), collapse = ", "), "\n"))
      cat(paste0("Selected variable set: ", paste(vars$names.kept, collapse = ", "), "\n"))
      selected_vars <- c(self$endPoint, self$terms)
      
      # end timing
      options(datadist=NULL)
      end <- Sys.time()
      duration <- round(as.numeric(end - start), 2)
      cat(paste0("Learning finished in: ", duration, " seconds.\n"))
      
      selected_vars
    },
    #' @description 
    #' Fit the RandomForest
    #' 
    #' @param x Training data of class data.frame
    fit = function() {
      self$data |>
        dplyr::select(c(self$endPoint, self$terms)) -> train_tbl
      train_tbl <- private$check_data(train_tbl)
      
      #  datadist scoping
      regression_data <<- rms::datadist(train_tbl)
      options(datadist="regression_data")
      
      # train regression model
      func <- get(self$model, envir = as.environment('package:rms'))
      params <- self$model_params
      params$data <- train_tbl
      params$formula <- self$formula
      self$model_fit <- pryr::do_call(func, params)
      
      nVars <- length(self$terms) 
      weights <- vector("list", nVars)
      names(weights) <- self$terms
      
      # get weights
      for (i in 1:nVars) {
        if (is.factor(train_tbl[[self$terms[i]]])) {
          nLev <- nlevels(train_tbl[[self$terms[i]]])
          weightsTmp <- rep(NA, times = nLev)
          names(weightsTmp) <- levels(train_tbl[[self$terms[i]]])
          for (j in 1:nLev) {
            myLevel <- paste(self$terms[i], "=", levels(train_tbl[[self$terms[i]]])[j], sep="")
            if (j==1) {
              weightsTmp[j] <- 0
            } else {
              weightsTmp[j] <- self$model_fit$coefficients[myLevel]
            }
          }
          weights[[i]] <- weightsTmp
        } else {  # else numeric
          myLevel <- paste(self$terms[i])
          weights[[i]] <- self$model_fit$coefficients[myLevel]
        }
      }
      self$weights <- weights
      options(datadist=NULL)
    }
  ),
  private = list(
    # check weights on NA
    check_weights = function() {
      wNA <- unlist(lapply(self$weights, function(x) any(is.na(x))))
      if (any(wNA)) {
        cat(paste0("Variables: ", names(wNA)[which(wNA)], " have NA weights.\n"))
        return(TRUE)
      }
      return(FALSE)
    },
    # transform_data:
    # we transform all factors to their corresponding
    # weights and set weight equal to 1 for factor variables
    transform_data = function(queryData, dtData, learnVars, weights) {
      nVars <- length(learnVars)
      trafoWeights <- rep(0, nVars)
      for (j in 1:nVars) {
        if (is.factor(dtData[[learnVars[j]]])) {
          if (!is.null(queryData)) {
            queryData[[learnVars[j]]] <- weights[[learnVars[j]]][queryData[[learnVars[j]]]]
          }
          dtData[[learnVars[j]]] <- weights[[learnVars[j]]][dtData[[learnVars[j]]]]
          trafoWeights[j] <- 1
        } else { # else keep weights
          trafoWeights[j] <- weights[[learnVars[j]]]
        }
      }
      names(trafoWeights) <- NULL
      
      if(is.null(queryData)) {
        queryData <- NULL
      } else {
        queryData <- unname(as.matrix(queryData[, learnVars, with=F]))
      }
      return(list(queryData    = queryData,
                  data         = unname(as.matrix(dtData[, learnVars, with=F])),
                  trafoWeights = trafoWeights))
    },
    # calculate weighted absolute distance 
    get_distance_matrix=function(query = NULL) {
      # learn if weights are empty
      testthat::expect_is(self$weights, "list", info = "Model not trained")
      testthat::expect_false(private$check_weights(), info = "NA values in regression beta coefficients!")
      
      if (!is.null(query)) {
        query <- data.table::copy(query)
      } 
      
      # transform for weighted distance calculations
      training_data_list <- private$transform_data(queryData = query,  
                                                   dtData    = self$data, 
                                                   learnVars = self$terms, 
                                                   weights   = self$weights)
      
      # calculate distance matrix
      self$distMat <- weightedDistance(x       = training_data_list$data, 
                                       y       = training_data_list$queryData, 
                                       weights = training_data_list$trafoWeights) |> 
        as.matrix()
    }
  )
)