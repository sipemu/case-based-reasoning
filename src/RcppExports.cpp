// Generated by using Rcpp::compileAttributes() -> do not edit by hand
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <RcppArmadillo.h>
#include <Rcpp.h>

using namespace Rcpp;

// cpp_weightedDistance
arma::vec cpp_weightedDistance(arma::mat& x, arma::rowvec& weights);
RcppExport SEXP _CaseBasedReasoning_cpp_weightedDistance(SEXP xSEXP, SEXP weightsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type x(xSEXP);
    Rcpp::traits::input_parameter< arma::rowvec& >::type weights(weightsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_weightedDistance(x, weights));
    return rcpp_result_gen;
END_RCPP
}
// cpp_weightedDistanceXY
arma::mat cpp_weightedDistanceXY(arma::mat& x, arma::mat& y, arma::rowvec& weights);
RcppExport SEXP _CaseBasedReasoning_cpp_weightedDistanceXY(SEXP xSEXP, SEXP ySEXP, SEXP weightsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type x(xSEXP);
    Rcpp::traits::input_parameter< arma::mat& >::type y(ySEXP);
    Rcpp::traits::input_parameter< arma::rowvec& >::type weights(weightsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_weightedDistanceXY(x, y, weights));
    return rcpp_result_gen;
END_RCPP
}
// cpp_TerminalNodeDistance
Rcpp::DataFrame cpp_TerminalNodeDistance(arma::umat& terminalNodeIDs);
RcppExport SEXP _CaseBasedReasoning_cpp_TerminalNodeDistance(SEXP terminalNodeIDsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::umat& >::type terminalNodeIDs(terminalNodeIDsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_TerminalNodeDistance(terminalNodeIDs));
    return rcpp_result_gen;
END_RCPP
}
// cpp_proximityMatrix
arma::vec cpp_proximityMatrix(arma::mat& nodeIDs);
RcppExport SEXP _CaseBasedReasoning_cpp_proximityMatrix(SEXP nodeIDsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type nodeIDs(nodeIDsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_proximityMatrix(nodeIDs));
    return rcpp_result_gen;
END_RCPP
}
// cpp_proximityMatrixRangerXY
arma::mat cpp_proximityMatrixRangerXY(arma::mat& xNodeIDs, arma::mat& yNodeIDs);
RcppExport SEXP _CaseBasedReasoning_cpp_proximityMatrixRangerXY(SEXP xNodeIDsSEXP, SEXP yNodeIDsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type xNodeIDs(xNodeIDsSEXP);
    Rcpp::traits::input_parameter< arma::mat& >::type yNodeIDs(yNodeIDsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_proximityMatrixRangerXY(xNodeIDs, yNodeIDs));
    return rcpp_result_gen;
END_RCPP
}
// cpp_depthMatrix
arma::vec cpp_depthMatrix(arma::mat& xNodeIDs, arma::umat& terminalNodeIDs);
RcppExport SEXP _CaseBasedReasoning_cpp_depthMatrix(SEXP xNodeIDsSEXP, SEXP terminalNodeIDsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type xNodeIDs(xNodeIDsSEXP);
    Rcpp::traits::input_parameter< arma::umat& >::type terminalNodeIDs(terminalNodeIDsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_depthMatrix(xNodeIDs, terminalNodeIDs));
    return rcpp_result_gen;
END_RCPP
}
// cpp_depthMatrixRangerXY
arma::mat cpp_depthMatrixRangerXY(arma::mat& xNodeIDs, arma::mat& yNodeIDs, arma::umat& terminalNodeIDs);
RcppExport SEXP _CaseBasedReasoning_cpp_depthMatrixRangerXY(SEXP xNodeIDsSEXP, SEXP yNodeIDsSEXP, SEXP terminalNodeIDsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type xNodeIDs(xNodeIDsSEXP);
    Rcpp::traits::input_parameter< arma::mat& >::type yNodeIDs(yNodeIDsSEXP);
    Rcpp::traits::input_parameter< arma::umat& >::type terminalNodeIDs(terminalNodeIDsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_depthMatrixRangerXY(xNodeIDs, yNodeIDs, terminalNodeIDs));
    return rcpp_result_gen;
END_RCPP
}
// weighted_knn
Rcpp::List weighted_knn(arma::mat x, arma::mat query, arma::vec weights, const char sortDirection, const std::size_t k);
RcppExport SEXP _CaseBasedReasoning_weighted_knn(SEXP xSEXP, SEXP querySEXP, SEXP weightsSEXP, SEXP sortDirectionSEXP, SEXP kSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat >::type x(xSEXP);
    Rcpp::traits::input_parameter< arma::mat >::type query(querySEXP);
    Rcpp::traits::input_parameter< arma::vec >::type weights(weightsSEXP);
    Rcpp::traits::input_parameter< const char >::type sortDirection(sortDirectionSEXP);
    Rcpp::traits::input_parameter< const std::size_t >::type k(kSEXP);
    rcpp_result_gen = Rcpp::wrap(weighted_knn(x, query, weights, sortDirection, k));
    return rcpp_result_gen;
END_RCPP
}
// cpp_orderMatrix
arma::umat cpp_orderMatrix(arma::mat& x, const int sortDirection, int k);
RcppExport SEXP _CaseBasedReasoning_cpp_orderMatrix(SEXP xSEXP, SEXP sortDirectionSEXP, SEXP kSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type x(xSEXP);
    Rcpp::traits::input_parameter< const int >::type sortDirection(sortDirectionSEXP);
    Rcpp::traits::input_parameter< int >::type k(kSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_orderMatrix(x, sortDirection, k));
    return rcpp_result_gen;
END_RCPP
}
// cpp_orderVector
arma::uvec cpp_orderVector(arma::vec x, const int sortDirection, int k);
RcppExport SEXP _CaseBasedReasoning_cpp_orderVector(SEXP xSEXP, SEXP sortDirectionSEXP, SEXP kSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::vec >::type x(xSEXP);
    Rcpp::traits::input_parameter< const int >::type sortDirection(sortDirectionSEXP);
    Rcpp::traits::input_parameter< int >::type k(kSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_orderVector(x, sortDirection, k));
    return rcpp_result_gen;
END_RCPP
}
// cpp_terminalNodeID
arma::vec cpp_terminalNodeID(arma::mat& x, arma::vec& childNodes1, arma::vec& childNodes2, arma::vec& splitValues, arma::vec& splitVarIds);
RcppExport SEXP _CaseBasedReasoning_cpp_terminalNodeID(SEXP xSEXP, SEXP childNodes1SEXP, SEXP childNodes2SEXP, SEXP splitValuesSEXP, SEXP splitVarIdsSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat& >::type x(xSEXP);
    Rcpp::traits::input_parameter< arma::vec& >::type childNodes1(childNodes1SEXP);
    Rcpp::traits::input_parameter< arma::vec& >::type childNodes2(childNodes2SEXP);
    Rcpp::traits::input_parameter< arma::vec& >::type splitValues(splitValuesSEXP);
    Rcpp::traits::input_parameter< arma::vec& >::type splitVarIds(splitVarIdsSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_terminalNodeID(x, childNodes1, childNodes2, splitValues, splitVarIds));
    return rcpp_result_gen;
END_RCPP
}
// cpp_weighted_knn
Rcpp::List cpp_weighted_knn(arma::mat x, arma::mat query, arma::vec weights, const std::size_t k);
RcppExport SEXP _CaseBasedReasoning_cpp_weighted_knn(SEXP xSEXP, SEXP querySEXP, SEXP weightsSEXP, SEXP kSEXP) {
BEGIN_RCPP
    Rcpp::RObject rcpp_result_gen;
    Rcpp::RNGScope rcpp_rngScope_gen;
    Rcpp::traits::input_parameter< arma::mat >::type x(xSEXP);
    Rcpp::traits::input_parameter< arma::mat >::type query(querySEXP);
    Rcpp::traits::input_parameter< arma::vec >::type weights(weightsSEXP);
    Rcpp::traits::input_parameter< const std::size_t >::type k(kSEXP);
    rcpp_result_gen = Rcpp::wrap(cpp_weighted_knn(x, query, weights, k));
    return rcpp_result_gen;
END_RCPP
}

static const R_CallMethodDef CallEntries[] = {
    {"_CaseBasedReasoning_cpp_weightedDistance", (DL_FUNC) &_CaseBasedReasoning_cpp_weightedDistance, 2},
    {"_CaseBasedReasoning_cpp_weightedDistanceXY", (DL_FUNC) &_CaseBasedReasoning_cpp_weightedDistanceXY, 3},
    {"_CaseBasedReasoning_cpp_TerminalNodeDistance", (DL_FUNC) &_CaseBasedReasoning_cpp_TerminalNodeDistance, 1},
    {"_CaseBasedReasoning_cpp_proximityMatrix", (DL_FUNC) &_CaseBasedReasoning_cpp_proximityMatrix, 1},
    {"_CaseBasedReasoning_cpp_proximityMatrixRangerXY", (DL_FUNC) &_CaseBasedReasoning_cpp_proximityMatrixRangerXY, 2},
    {"_CaseBasedReasoning_cpp_depthMatrix", (DL_FUNC) &_CaseBasedReasoning_cpp_depthMatrix, 2},
    {"_CaseBasedReasoning_cpp_depthMatrixRangerXY", (DL_FUNC) &_CaseBasedReasoning_cpp_depthMatrixRangerXY, 3},
    {"_CaseBasedReasoning_weighted_knn", (DL_FUNC) &_CaseBasedReasoning_weighted_knn, 5},
    {"_CaseBasedReasoning_cpp_orderMatrix", (DL_FUNC) &_CaseBasedReasoning_cpp_orderMatrix, 3},
    {"_CaseBasedReasoning_cpp_orderVector", (DL_FUNC) &_CaseBasedReasoning_cpp_orderVector, 3},
    {"_CaseBasedReasoning_cpp_terminalNodeID", (DL_FUNC) &_CaseBasedReasoning_cpp_terminalNodeID, 5},
    {"_CaseBasedReasoning_cpp_weighted_knn", (DL_FUNC) &_CaseBasedReasoning_cpp_weighted_knn, 4},
    {NULL, NULL, 0}
};

RcppExport void R_init_CaseBasedReasoning(DllInfo *dll) {
    R_registerRoutines(dll, NULL, CallEntries, NULL, NULL);
    R_useDynamicSymbols(dll, FALSE);
}
