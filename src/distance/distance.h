#ifndef DISTANCE_H
#define DISTANCE_H

// [[Rcpp::depends(RcppArmadillo)]]
#include<RcppArmadillo.h>

#include "../ranger/forestTopology.h"

class distance {
public:
  distance() {};
  
  virtual double calc_distance(const arma::subview_row<double>& x, const arma::subview_row<double>& y) const {
    return 0.0;
  };
  
  void set_parameters() {};
};

// weighted distance
class weightedDistance final : public distance {
public:
  virtual double calc_distance(const arma::subview_row<double>& x, const arma::subview_row<double>& y) const {
    return arma::sum(arma::abs(weights_ % (x - y)));
  };
  
  void set_parameters(arma::rowvec& weights) {
    weights_ = weights;
  };
private:
  arma::rowvec weights_;
};

// random forest proximity
class rangerProximity : public distance {
public:
  virtual double calc_distance(const arma::subview_row<double>& x, const arma::subview_row<double>& y) const {
    int similarity = 0;
    for (std::size_t i=0;i<x.n_elem;++i) {
      if (x(i) == y(i)) {
        ++similarity;
      }
    }
    return similarity * 1. / nTrees_;
  };
  
  void set_parameters(std::uint32_t nTrees) {
    nTrees_ = nTrees;
  };
private:
  std::uint32_t nTrees_;
};

// random forest depth distance: sum over trees of the number of edges between
// the terminal nodes of x and y
class rfDepthDistance final : public distance {
public:
  virtual double calc_distance(const arma::subview_row<double>& x, const arma::subview_row<double>& y) const {
    double sum = 0.0;
    const std::size_t nTrees = topology_.nTrees();
    for (std::size_t t=0; t<nTrees; ++t) {
      const int a = static_cast<int>(x[t]);
      const int b = static_cast<int>(y[t]);
      if (a != b) {
        sum += topology_.edges(t, a, b);
      }
    }
    return sum;
  };

  void set_parameters(const ForestTopology& topology) {
    topology_ = topology;
  };
private:
  ForestTopology topology_;
};

#endif
