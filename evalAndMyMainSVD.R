# source("mymain.R")

library(lubridate)
library(tidyverse)
library(tidyr)
library(dplyr)
# read in train / test dataframes
train <- readr::read_csv('train_ini.csv')
test <- readr::read_csv('test.csv')

# wae: record weighted mean absolute error WMAE
num_folds <- 10
wae <- rep(0, num_folds)

for (t in 1:num_folds) {
  
#############################
  # *** THIS IS YOUR PREDICTION FUNCTION ***
  
  preprocess.svd <- function(train, n.comp){
    # Replaces the training data with a rank-reduced approximation of itself.
    # This is for noise reduction. The intuition is that characteristics
    # that are common across stores (within the same department) are probably
    # signal, while those that are unique to one store may be noise.
    #
    # args:
    # train - A matrix of Weekly_Sales values from the training set of dimension
    #         (number of weeeks in training data) x (number of stores)
    # n.comp - the number of components to keep in the singular value
    #         decomposition
    #
    # returns:
    #  the rank-reduced approximation of the training data
    
    if(nrow(train) > n.comp){
      z <- svd(train[, 2:ncol(train)], nu=n.comp, nv=n.comp)
      s <- diag(z$d[1:n.comp])
      train[, 2:ncol(train)] <- z$u %*% s %*% t(z$v)
    }
    return(train)
  }
  
  mypredict = function(){
    
    start_date <- ymd("2011-03-01") %m+% months(2 * (t - 1))
    end_date <- ymd("2011-05-01") %m+% months(2 * (t - 1))
    test_current <- test %>%
      filter(Date >= start_date & Date < end_date) %>%
      select(-IsHoliday)
    
    test_current <- test_current %>%
      mutate(Wk = week(Date))
    
    # not all depts need prediction
    test_depts <- unique(test_current$Dept)
    test_pred <- NULL
    
    train <- train %>% select(Store, Dept, Date, Weekly_Sales) %>% spread(Date, Weekly_Sales)
    train[is.na(train)] <- 0
    
    for(dept in test_depts){
      train_dept_data <- train %>% filter(Dept == dept)
      #convert each department into a reduced data matrix
      #
      train_svd <- preprocess.svd(train_dept_data, 8) 
      train <- train_svd %>% gather(Date, Weekly_Sales, -Store, -Dept)
    }
    print(train)
    
    # find the unique pairs of (Store, Dept) combo that appeared in both training and test sets
    train_pairs <- train[, 1:2] %>% count(Store, Dept) %>% filter(n != 0)
    test_pairs <- test_current[, 1:2] %>% count(Store, Dept) %>% filter(n != 0)
    unique_pairs <- intersect(train_pairs[, 1:2], test_pairs[, 1:2])
    
    print("1:code and combine training samples in train_split list")
    # pick out the needed training samples, convert to dummy coding, then put them into a list
    train_split <- unique_pairs %>% 
      left_join(train, by = c('Store', 'Dept')) %>% 
      mutate(Wk = factor(ifelse(year(Date) == 2010, week(Date) - 1, week(Date)), levels = 1:52)) %>% 
      mutate(Yr = year(Date))
    
    print("3")
    train_split = as_tibble(model.matrix(~ Weekly_Sales + Store + Dept + Yr + Wk, train_split)) %>% group_split(Store, Dept)
    
    print("2:code and combine test samples in test_split list")
    # do the same for the test set
    test_split <- unique_pairs %>% 
      left_join(test_current, by = c('Store', 'Dept')) %>% 
      mutate(Wk = factor(ifelse(year(Date) == 2010, week(Date) - 1, week(Date)), levels = 1:52)) %>% 
      mutate(Yr = year(Date))
    
    test_split = as_tibble(model.matrix(~ Store + Dept + Yr + Wk, test_split)) %>% 
      mutate(Date = test_split$Date) %>% 
      group_split(Store, Dept)
    
    # pre-allocate a list to store the predictions
    test_pred <- vector(mode = "list", length = nrow(unique_pairs))
    
    # perform regression for each split (unique dept-store combination?)
    # we used lm.fit instead of lm
      
    for (i in 1:nrow(unique_pairs)) {
      tmp_train <- train_split[[i]] #We are taking a list from a list of lists?
      tmp_test <- test_split[[i]]
      
      # shift for fold 5
      if (t==5){
        shift = 1/7
        tmp_test[, "Wk51"] = tmp_test[, "Wk51"] * (1-shift) + 
          tmp_test[, "Wk52"] * shift
      }    

      mycoef <- lm.fit(as.matrix(tmp_train[, -(2:4)]), tmp_train$Weekly_Sales)$coefficients
      mycoef[is.na(mycoef)] <- 0
      tmp_pred <- mycoef[1] + as.matrix(tmp_test[, 4:55]) %*% mycoef[-1]
      
      test_pred[[i]] <- cbind(tmp_test[, 2:3], Date = tmp_test$Date, Weekly_Pred = tmp_pred[,1])
    }
    
    # turn the list into a table at once, 
    # this is much more efficient then keep concatenating small tables
    test_pred <- bind_rows(test_pred)
    
    return(test_pred)
  }
  ########################################
  test_pred <- mypredict()
  
  # read new data from fold_t 
  fold_file <- paste0('fold_', t, '.csv')
  new_train <- readr::read_csv(fold_file, 
                               col_types = cols())
  
  # extract predictions matching up to the new data
  scoring_tbl <- new_train %>% 
    left_join(test_pred, by = c('Date', 'Store', 'Dept'))
  
  # compute WMAE
  actuals <- scoring_tbl$Weekly_Sales
  preds <- scoring_tbl$Weekly_Pred
  preds[is.na(preds)] <- 0
  weights <- if_else(scoring_tbl$IsHoliday, 5, 1)
  wae[t] <- sum(weights * abs(actuals - preds)) / sum(weights)
  
  # update train data and get ready to predict at (t+1)
  train <- train %>% add_row(new_train)
}

print(wae)
mean(wae)
