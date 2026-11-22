# Case-base maintenance: noisy cases and competence categories (#46)

# Leave-one-out assessment of a case base.
#   dist: n x n distances between the cases (diagonal is ignored)
#   y:    outcome_values() of the cases
#   k:    number of neighbours
#   tol:  tolerance for numeric outcomes (same outcome if |y_i - y_j| <= tol)
assess_case_base <- function(dist, y, k, tol) {
  n <- nrow(dist)
  diag(dist) <- Inf
  nn <- matrix(cpp_orderMatrix(dist, sortDirection = 0, k = k), nrow = k)
  v <- y$value
  known <- !is.na(v)
  same <- function(i, j) {
    if (y$type == "numeric") abs(v[j] - v[i]) <= tol else v[j] == v[i]
  }

  agreement <- rep(NA_real_, n)
  noisy <- rep(NA, n)
  # solves[j, i]: case j is among the k nearest neighbours of i and has the
  # same outcome
  solves <- matrix(FALSE, n, n)
  for (i in seq_len(n)) {
    if (!known[i]) next
    nb <- nn[, i]
    nb <- nb[known[nb]]
    if (length(nb) == 0) next
    ok <- same(i, nb)
    agreement[i] <- mean(ok)
    solves[nb[ok], i] <- TRUE
    noisy[i] <- if (y$type == "numeric") {
      abs(mean(v[nb]) - v[i]) > tol
    } else {
      tab <- table(v[nb])
      names(tab)[which.max(tab)] != v[i]
    }
  }

  n_reach <- colSums(solves)
  n_cover <- rowSums(solves)
  category <- rep(NA_character_, n)
  for (i in which(known)) {
    reach <- which(solves[, i])
    if (length(reach) == 0) {
      category[i] <- "pivotal"
      next
    }
    # coverage including the case itself (Smyth & Keane, 1995)
    cov_i <- c(i, which(solves[i, ]))
    aux <- any(vapply(reach, function(j) all(cov_i %in% c(j, which(solves[j, ]))), logical(1)))
    category[i] <- if (aux) "auxiliary" else "other"
  }

  data.frame(agreement   = agreement,
             noisy       = noisy,
             n_reachable = as.integer(n_reach),
             n_coverage  = as.integer(n_cover),
             category    = factor(category, levels = c("pivotal", "auxiliary", "other")),
             stringsAsFactors = FALSE)
}
