# Survival prediction from retrieved cases and its evaluation (#21)

# Weighted Kaplan-Meier estimate of S(t) at `times`.
km_at <- function(time, status, weights, times) {
  ord <- order(time)
  time <- time[ord]
  status <- status[ord]
  weights <- weights[ord]
  ev_times <- unique(time[status == 1])
  if (length(ev_times) == 0) {
    return(rep(1, length(times)))
  }
  at_risk <- vapply(ev_times, function(t) sum(weights[time >= t]), numeric(1))
  events <- vapply(ev_times, function(t) sum(weights[time == t & status == 1]), numeric(1))
  surv <- cumprod(1 - events / at_risk)
  idx <- findInterval(times, ev_times)
  c(1, surv)[idx + 1]
}

# Kaplan-Meier estimate of the censoring distribution G(t) = P(C > t),
# evaluated at `times`; `left = TRUE` gives the left limit G(t-).
censoring_km <- function(time, status, times, left = FALSE) {
  g <- km_at(time, 1 - status, rep(1, length(time)), sort(unique(time)))
  ut <- sort(unique(time))
  idx <- if (left) findInterval(times, ut, left.open = TRUE) else findInterval(times, ut)
  c(1, g)[idx + 1]
}

# tricube kernel weights from distances, bandwidth = largest distance + epsilon
tricube_weights <- function(d) {
  h <- max(d) * 1.0001 + .Machine$double.eps
  (1 - (d / h)^3)^3
}

# Survival predictions (rows: queries, columns: times) from the k nearest
# training cases of each query.
predict_survival_cases <- function(dist, time, status, k, times, weighted) {
  order_mat <- cpp_orderMatrix(dist, sortDirection = 0, k = k)
  surv <- vapply(seq_len(ncol(dist)), function(q) {
    nn <- order_mat[, q]
    w <- if (weighted) tricube_weights(dist[nn, q]) else rep(1, length(nn))
    km_at(time[nn], status[nn], w, times)
  }, numeric(length(times)))
  surv <- matrix(surv, nrow = length(times))
  surv <- t(surv)
  colnames(surv) <- format(times)
  surv
}

# IPCW Brier score (Graf et al., 1999) at each of `times`.
brier_ipcw <- function(surv, time, status, times, train_time, train_status) {
  vapply(seq_along(times), function(j) {
    t <- times[j]
    s <- surv[, j]
    g_t <- censoring_km(train_time, train_status, t)
    g_ti <- censoring_km(train_time, train_status, time, left = TRUE)
    event_before <- time <= t & status == 1
    alive <- time > t
    w1 <- ifelse(event_before & g_ti > 0, 1 / g_ti, 0)
    w2 <- if (g_t > 0) 1 / g_t else 0
    mean(s^2 * w1 + (1 - s)^2 * alive * w2)
  }, numeric(1))
}

# trapezoidal integral of y over x, divided by the range of x
integrate_mean <- function(x, y) {
  if (length(x) < 2) return(y[1])
  sum(diff(x) * (utils::head(y, -1) + utils::tail(y, -1)) / 2) / (max(x) - min(x))
}
