// [[Rcpp::depends(RcppParallel)]]
// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>
#include <RcppParallel.h>

#include <vector>
#include <algorithm>

// Out-of-bag aware random forest proximities between training cases (rows of
// the result) and query cases (columns).
//
// xNodes:  n x T terminal node ids of the training data (0-based)
// yNodes:  m x T terminal node ids of the query data
// inbag:   n x T in-bag counts of the training data
// yInbag:  m x T in-bag counts of the query, or an empty matrix for new data.
//          For in-sample queries (query = training data) this is the same as
//          `inbag`; a query then only uses the trees in which it is out-of-bag.
// type:    0 = OOB proximity: share of trees in which the training case and the
//              query are both out-of-bag and share a terminal node.
//          1 = RF-GAP (Rhodes, Cutler & Moon 2023): for query q and training
//              case j, the average over trees where q is out-of-bag of
//              c_j(t) 1[same leaf] / |M_q(t)|, with c_j(t) the in-bag count of
//              j and |M_q(t)| the total in-bag count in q's leaf.
struct oobProximityWorker : public RcppParallel::Worker {
  const arma::mat& xNodes_;
  const arma::mat& yNodes_;
  const arma::mat& inbag_;
  const arma::mat& yInbag_;
  const std::vector<std::vector<double> >& leafMass_;
  const int type_;
  arma::mat& output_;

  oobProximityWorker(const arma::mat& xNodes, const arma::mat& yNodes,
                     const arma::mat& inbag, const arma::mat& yInbag,
                     const std::vector<std::vector<double> >& leafMass,
                     const int type, arma::mat& output)
    : xNodes_(xNodes), yNodes_(yNodes), inbag_(inbag), yInbag_(yInbag),
      leafMass_(leafMass), type_(type), output_(output) {}

  bool queryOOB(std::size_t q, std::size_t t) const {
    return yInbag_.n_elem == 0 || yInbag_(q, t) == 0;
  }

  void operator()(std::size_t begin, std::size_t end) {
    const std::size_t nTrees = xNodes_.n_cols;
    for (std::size_t q = begin; q < end; ++q) {
      for (std::size_t i = 0; i < xNodes_.n_rows; ++i) {
        double num = 0.0;
        double den = 0.0;
        for (std::size_t t = 0; t < nTrees; ++t) {
          if (!queryOOB(q, t)) continue;
          if (type_ == 0) {
            if (inbag_(i, t) != 0) continue;
            den += 1.0;
            if (xNodes_(i, t) == yNodes_(q, t)) num += 1.0;
          } else {
            den += 1.0;
            const double c = inbag_(i, t);
            if (c > 0 && xNodes_(i, t) == yNodes_(q, t)) {
              num += c / leafMass_[t][static_cast<std::size_t>(yNodes_(q, t))];
            }
          }
        }
        output_(i, q) = den > 0 ? num / den : 0.0;
      }
    }
  }
};

// [[Rcpp::export]]
arma::mat cpp_oobProximity(arma::mat& xNodes, arma::mat& yNodes, arma::mat& inbag,
                           arma::mat& yInbag, int type) {
  if (xNodes.n_cols != yNodes.n_cols || inbag.n_rows != xNodes.n_rows ||
      inbag.n_cols != xNodes.n_cols) {
    Rcpp::stop("Dimensions of terminal nodes and in-bag counts do not match.");
  }
  if (yInbag.n_elem > 0 && (yInbag.n_rows != yNodes.n_rows || yInbag.n_cols != yNodes.n_cols)) {
    Rcpp::stop("Dimensions of query terminal nodes and in-bag counts do not match.");
  }
  const std::size_t nTrees = xNodes.n_cols;

  // total in-bag count per leaf and tree
  std::vector<std::vector<double> > leafMass(nTrees);
  for (std::size_t t = 0; t < nTrees; ++t) {
    double maxNode = std::max(xNodes.col(t).max(), yNodes.col(t).max());
    leafMass[t].assign(static_cast<std::size_t>(maxNode) + 1, 0.0);
    for (std::size_t i = 0; i < xNodes.n_rows; ++i) {
      leafMass[t][static_cast<std::size_t>(xNodes(i, t))] += inbag(i, t);
    }
  }

  arma::mat output(xNodes.n_rows, yNodes.n_rows, arma::fill::zeros);
  oobProximityWorker worker(xNodes, yNodes, inbag, yInbag, leafMass, type, output);
  RcppParallel::parallelFor(0, yNodes.n_rows, worker);
  return output;
}
