# Walmart Store Sales Forecasting with SVD/PCA Regression

**Team:** Mohammad Hassanpour ([@mohassan99](https://github.com/mohassan99)) · Jason Young (jasony6) · Unnati Narang (unnati)

---

## Overview

This project forecasts weekly sales for 45 Walmart stores across 99 departments using a rolling-window linear regression approach with SVD-based noise reduction. Sales are predicted for 10 consecutive two-month test folds spanning March 2011 through October 2012.

**Best result:** Mean WMAE of **1583.40** across 10 folds, with an average run time of 1.82 seconds per fold.

---

## Method Summary

1. **Date-aligned training windows** — For each fold, the training set is filtered to the same weeks-of-year as the test set (e.g., training on weeks 7–14 of the prior year to predict weeks 7–14 of the current year).
2. **SVD preprocessing** — Each department's training matrix (stores × weeks) is decomposed via Singular Value Decomposition. Only the 8 largest singular values are retained, suppressing store-specific noise while preserving cross-store demand signal.
3. **Per-(Store, Dept) regression** — A separate OLS model is fit for each store-department pair using week and year as dummy-coded predictors. Coefficients are estimated with `lm.fit()` for speed.
4. **Rolling update** — After each fold is predicted, that fold's actuals are appended to the training set before predicting the next fold.

Evaluation metric: **Weighted Mean Absolute Error (WMAE)**, where holiday weeks are weighted 5×.

---

## Files

| File | Description |
|------|-------------|
| `mymain.R` | Final submitted prediction function with SVD preprocessing |
| `mymainSVD.R` | Annotated version of mymain with inline comments explaining each step |
| `mymain_old.R` | Baseline regression without SVD (earlier iteration) |
| `evalAndMyMainSVD.R` | Full evaluation harness: runs the 10-fold WMAE loop end-to-end |
| `TEAM_REPORT.md` | Team write-up with methods, results table, and discussion |

---

## Results

| Fold | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | Avg |
|------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|------|
| WMAE | 1941.58 | 1363.46 | 1382.50 | 1527.28 | 2056.66 | 1635.78 | 1682.75 | 1399.60 | 1418.08 | 1426.26 | **1583.40** |

Fold 5 is the worst-performing fold due to a calendar boundary issue; a 1/7-day shift adjustment on week 51 was applied to partially mitigate it.

---

## Data

Data provided by the course (not included in this repo). Required files to run `evalAndMyMainSVD.R`:

- `train_ini.csv` — initial training data (Feb 2010–Feb 2011)
- `test.csv` — test set with Store/Dept/Date entries for all folds
- `fold_1.csv` through `fold_10.csv` — actuals for each fold (used for scoring and rolling training update)

---

## Related Repos

| Project | Repo |
|---------|------|
| P1 — Ames Housing Regression | [Housing-Price-Prediction-XGBoost-GLMNet](https://github.com/mohassan99/Housing-Price-Prediction-XGBoost-GLMNet) |
| P3 — IMDB Sentiment Analysis | [Sentiment-Analysis](https://github.com/mohassan99/Sentiment-Analysis) |
| P4 — Movie Recommender System | [Movie-Recommender---Collaborative-Filtering](https://github.com/mohassan99/Movie-Recommender---Collaborative-Filtering) |
