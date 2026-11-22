## Submission

This release fixes the install warning reported on the CRAN check page
("replacing previous import rms::cluster by survival::cluster") by no longer
importing the full rms and survival namespaces, and importing only the
functions used (`rms::fastbw`, `survival::cox.zph`).

It also fixes several correctness bugs (factor level alignment between query
and training data, missing value handling, the random forest depth distance)
and adds new features: splines and interactions in regression-based
distances, out-of-bag and RF-GAP random forest proximities, survival
prediction from retrieved cases, counterfactual case retrieval and match
explanations. See NEWS.md.

## Test environments

- macOS (GitHub Actions): R release
- Windows (GitHub Actions): R release
- Ubuntu (GitHub Actions): R devel, R release, R oldrel-1
- Local: Manjaro Linux, R release

## R CMD check results

0 errors | 0 warnings | 0 notes

## Downstream dependencies

There are currently no downstream dependencies for this package.
