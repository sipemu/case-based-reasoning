# Reuse: predict class and numeric outcomes from retrieved cases (#43)

# Outcome of the training cases for prediction. Class endpoints (factor,
# character, logical or 0/1) get their levels; levels of factors are kept in
# their order, other labels are sorted.
prediction_outcome <- function(df, endpoint) {
  y <- df[[endpoint]]
  out <- outcome_values(df, endpoint, NULL)
  if (out$type == "class") {
    out$levels <- if (is.factor(y)) {
      levels(y)[levels(y) %in% as.character(y)]
    } else {
      sort(unique(out$value[!is.na(out$value)]))
    }
  }
  out
}

# Predictions from the k nearest training cases of each query (columns of
# `dist`). `y` as returned by prediction_outcome(); for class outcomes
# missing labels are ignored. Returns a data.frame with column `prediction`
# and, for classes, one column `prob_<level>` per class.
predict_outcome_cases <- function(dist, y, k, weighted = FALSE) {
  order_mat <- matrix(cpp_orderMatrix(dist, sortDirection = 0, k = k), nrow = k)
  m <- ncol(dist)
  weights <- function(q) {
    if (weighted) tricube_weights(dist[order_mat[, q], q]) else rep(1, k)
  }
  if (y$type == "numeric") {
    pred <- vapply(seq_len(m), function(q) {
      w <- weights(q)
      sum(w * y$value[order_mat[, q]]) / sum(w)
    }, numeric(1))
    return(data.frame(prediction = pred))
  }
  lev <- y$levels
  probs <- matrix(0, nrow = m, ncol = length(lev))
  for (q in seq_len(m)) {
    v <- y$value[order_mat[, q]]
    w <- weights(q)
    keep <- !is.na(v)
    if (!any(keep)) {
      probs[q, ] <- NA
      next
    }
    s <- tapply(w[keep], factor(v[keep], levels = lev), sum)
    s[is.na(s)] <- 0
    probs[q, ] <- s / sum(w[keep])
  }
  best <- max.col(ifelse(is.na(probs), -1, probs), ties.method = "first")
  best[is.na(probs[, 1])] <- NA
  res <- data.frame(prediction = factor(lev[best], levels = lev))
  colnames(probs) <- paste0("prob_", lev)
  cbind(res, as.data.frame(probs, optional = TRUE))
}

# Accuracy, Brier score and log loss (classes) or RMSE and MAE (numeric).
evaluate_predictions <- function(pred, truth, y) {
  if (y$type == "numeric") {
    err <- pred$prediction - as.numeric(truth)
    return(list(rmse = sqrt(mean(err^2)), mae = mean(abs(err)), n = length(err)))
  }
  truth <- as.character(truth)
  probs <- as.matrix(pred[, paste0("prob_", y$levels), drop = FALSE])
  onehot <- outer(truth, y$levels, "==") * 1
  p_true <- rowSums(probs * onehot)
  list(accuracy = mean(as.character(pred$prediction) == truth),
       brier    = mean(rowSums((probs - onehot)^2)),
       log_loss = -mean(log(pmax(p_true, 1e-15))),
       n        = length(truth))
}
