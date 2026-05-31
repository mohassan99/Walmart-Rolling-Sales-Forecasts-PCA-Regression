# Team Report — Project 2: Walmart Store Sales Forecasting

**Course:** STAT 542 — Statistical Learning, Fall 2022  
**Team:** Mohammad Hassanpour (mh57), Jason Young (jasony6), Unnati Narang (unnati)

---

## Abstract

Linear regression, data pre-processing, and SVD-based principal component analysis were applied to predict Walmart weekly sales for 10 two-month test folds using rolling historical data. The final model achieved a mean WMAE of **1583.40** across all 10 folds with an average run time of 1.82 seconds per fold.

---

## Model Performance

| Fold | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | **Average** |
|------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------|-------------|
| WMAE | 1941.58 | 1363.46 | 1382.50 | 1527.28 | 2056.66 | 1635.78 | 1682.75 | 1399.60 | 1418.08 | 1426.26 | **1583.40** |

*Metric: Weighted Mean Absolute Error (WMAE). Holiday weeks (Super Bowl, Labor Day, Thanksgiving, Christmas) weighted 5×.*

---

## Introduction

The dataset covers 45 Walmart stores in different regions, comprising 421,570 observations of store, department, date, weekly sales, and a holiday indicator. The task is to predict sales for each department within each store.

The evaluation uses a rolling-window approach: an initial training set (February 2010–February 2011) predicts the first 2-month fold (March–April 2011), after which that fold's actuals are added to the training set and the model is re-trained to predict the next fold. This continues for all 10 folds through October 2012.

---

## Methods

### Data Pre-processing

Training and test data are preprocessed identically, with one key difference: only training data is transformed via SVD.

1. **Extract response:** Pull historical weekly sales per department per store.
2. **Align date ranges:** For each fold, restrict training data to the same weeks-of-year that appear in the test fold (e.g., if predicting weeks 7–14, train on weeks 7–14 of the prior year).
3. **Filter store-department pairs:** Keep only (Store, Dept) combinations present in both training and test sets for that fold.

### SVD Preprocessing (Principal Component Noise Reduction)

For each department:

- Arrange data as matrix **X** (stores × weeks).
- Center by subtracting the mean weekly sales for each week.
- Apply SVD: **X** = **U Σ V**ᵀ
- Reconstruct using the **8 largest singular values** to retain the dominant cross-store signal and suppress store-specific noise.
- Add back the column means.

The intuition is that patterns common across stores within a department are likely true demand signal, while store-unique variation is likely noise.

### Regression Model

For each (Store, Dept) pair, fit a linear model:

**Sales** = β₀ + β₁ · Week + β₂ · Year

Week and Year are encoded as dummy variables. The design matrix is constructed via `model.matrix()` and coefficients are estimated with `lm.fit()` for efficiency. NA coefficients are zeroed out before prediction.

**Fold 5 adjustment:** A 1/7-day shift is applied to Week 51 predictions to account for the calendar boundary, blending Week 51 and Week 52 dummy weights.

---

## Results

Test system: MacBook Pro (13-inch, 2020), 2.3 GHz Quad-Core Intel Core i7, 16 GB RAM.

See model performance table above. Fold 5 produced the highest error (2056.66), consistent with the holiday-season calendar boundary that required the week-shift adjustment.

---

## Discussion

Matching training data to each fold's date range (by week-of-year), filtering to relevant store-department pairs, and applying SVD noise reduction were the key design decisions that drove accuracy. Fitting a separate model per (Store, Dept) pair — rather than a single global model — allowed the approach to capture heterogeneous demand patterns across the 45-store dataset.
