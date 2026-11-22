#ifndef FORESTTOPOLOGY_H
#define FORESTTOPOLOGY_H

// [[Rcpp::depends(RcppArmadillo)]]
#include <RcppArmadillo.h>

#include <vector>

// Parent and depth of every node of every tree of a ranger forest.
//
// Built from the matrix returned by ranger_forests_to_matrix():
//   column 0: tree id (1-based), column 1: node id (1-based),
//   column 2/3: left/right child node id (0-based, 0 = no child).
// Node ids in the public API (terminal node ids from ranger) are 0-based.
//
// The number of edges between two nodes is computed on demand by walking both
// nodes up to their lowest common ancestor, so memory is O(#nodes) and no
// pairwise table is precomputed.
class ForestTopology {
public:
  ForestTopology() {};

  explicit ForestTopology(const arma::umat& forest) {
    const std::size_t nrow = forest.n_rows;
    std::size_t nTrees = 0;
    for (std::size_t i = 0; i < nrow; ++i) {
      nTrees = std::max<std::size_t>(nTrees, forest(i, 0));
    }
    parent_.assign(nTrees, std::vector<int>());
    depth_.assign(nTrees, std::vector<int>());

    // number of nodes per tree
    std::vector<std::size_t> nNodes(nTrees, 0);
    for (std::size_t i = 0; i < nrow; ++i) {
      const std::size_t t = forest(i, 0) - 1;
      nNodes[t] = std::max<std::size_t>(nNodes[t], forest(i, 1));
    }
    for (std::size_t t = 0; t < nTrees; ++t) {
      parent_[t].assign(nNodes[t], -1);
      depth_[t].assign(nNodes[t], 0);
    }

    // parent links
    for (std::size_t i = 0; i < nrow; ++i) {
      const std::size_t t = forest(i, 0) - 1;
      const int node = static_cast<int>(forest(i, 1)) - 1;
      for (int c = 2; c <= 3; ++c) {
        const int child = static_cast<int>(forest(i, c));
        if (child != 0) {
          parent_[t][child] = node;
        }
      }
    }

    // depths: depth-first traversal from the root
    for (std::size_t t = 0; t < nTrees; ++t) {
      std::vector<std::vector<int> > kids(nNodes[t]);
      for (std::size_t v = 0; v < nNodes[t]; ++v) {
        if (parent_[t][v] >= 0) {
          kids[parent_[t][v]].push_back(static_cast<int>(v));
        }
      }
      std::vector<int> stack;
      stack.push_back(0);
      while (!stack.empty()) {
        const int v = stack.back();
        stack.pop_back();
        for (int c : kids[v]) {
          depth_[t][c] = depth_[t][v] + 1;
          stack.push_back(c);
        }
      }
    }
  };

  std::size_t nTrees() const { return parent_.size(); };

  // number of edges between nodes a and b (0-based) in tree t (0-based)
  int edges(std::size_t t, int a, int b) const {
    const std::vector<int>& p = parent_[t];
    const std::vector<int>& d = depth_[t];
    int dist = 0;
    while (d[a] > d[b]) { a = p[a]; ++dist; }
    while (d[b] > d[a]) { b = p[b]; ++dist; }
    while (a != b) { a = p[a]; b = p[b]; dist += 2; }
    return dist;
  };

private:
  std::vector<std::vector<int> > parent_;
  std::vector<std::vector<int> > depth_;
};

#endif
