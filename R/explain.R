# Counterfactual cases and match explanations (#23)

# Outcome label of cases for counterfactual search.
#   type "class":    factor/character/logical or 0/1 endpoint -> label
#   type "numeric":  numeric endpoint -> value
#   type "survival": Surv(time, status) -> "event" (event before horizon),
#                    "no event" (followed beyond horizon) or NA (censored before)
outcome_values <- function(df, endpoint, horizon) {
  if (length(endpoint) == 2) {
    time <- df[[endpoint[1]]]
    status <- as.numeric(df[[endpoint[2]]])
    lab <- ifelse(time <= horizon & status == 1, "event",
                  ifelse(time > horizon, "no event", NA_character_))
    return(list(type = "survival", value = lab))
  }
  y <- df[[endpoint]]
  if (is.factor(y) || is.character(y) || is.logical(y) ||
      (is.numeric(y) && all(stats::na.omit(y) %in% c(0, 1)))) {
    return(list(type = "class", value = as.character(y)))
  }
  list(type = "numeric", value = as.numeric(y))
}

# Explain why two cases of a random forest are similar: in each tree where the
# cases fall into different terminal nodes, the split variable of the node at
# which their paths diverge (their lowest common ancestor).
explain_forest_match <- function(rf, q_nodes, c_nodes) {
  n_trees <- rf$num.trees
  vars <- character(0)
  for (t in seq_len(n_trees)) {
    a <- q_nodes[t]
    b <- c_nodes[t]
    if (a == b) next
    info <- ranger::treeInfo(rf, t)
    parent <- rep(NA_integer_, nrow(info))
    left <- info$leftChild
    right <- info$rightChild
    has_kids <- !is.na(left)
    parent[left[has_kids] + 1] <- info$nodeID[has_kids]
    parent[right[has_kids] + 1] <- info$nodeID[has_kids]
    path_a <- a
    while (!is.na(parent[path_a[length(path_a)] + 1])) {
      path_a <- c(path_a, parent[path_a[length(path_a)] + 1])
    }
    node <- b
    while (!(node %in% path_a)) {
      node <- parent[node + 1]
    }
    vars <- c(vars, info$splitvarName[node + 1])
  }
  n_diverge <- length(vars)
  all_vars <- rf$forest$independent.variable.names
  counts <- table(factor(vars, levels = all_vars))
  res <- data.frame(variable = all_vars,
                    n_trees  = as.integer(counts),
                    share    = if (n_diverge > 0) as.numeric(counts) / n_diverge else 0,
                    stringsAsFactors = FALSE)
  res <- res[order(-res$n_trees), , drop = FALSE]
  rownames(res) <- NULL
  attr(res, "same_leaf") <- 1 - n_diverge / n_trees
  res
}
