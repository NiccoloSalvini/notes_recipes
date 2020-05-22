
  - [“Reviem from eric ekholm”](#reviem-from-eric-ekholm)
      - [Load](#load)
      - [preprocess](#preprocess)

# “Reviem from eric ekholm”

*author*:
**[eric-ekholm](https://eric-ekholm.netlify.app/blog/tidymodels-walkthrough/)**
*date*: 22 maggio, 2020

## Load

load train data from kaggle competition:

``` r
train <- read_csv("train.csv") %>%
  clean_names()
```

    ## Parsed with column specification:
    ## cols(
    ##   .default = col_character(),
    ##   Id = col_double(),
    ##   MSSubClass = col_double(),
    ##   LotFrontage = col_double(),
    ##   LotArea = col_double(),
    ##   OverallQual = col_double(),
    ##   OverallCond = col_double(),
    ##   YearBuilt = col_double(),
    ##   YearRemodAdd = col_double(),
    ##   MasVnrArea = col_double(),
    ##   BsmtFinSF1 = col_double(),
    ##   BsmtFinSF2 = col_double(),
    ##   BsmtUnfSF = col_double(),
    ##   TotalBsmtSF = col_double(),
    ##   `1stFlrSF` = col_double(),
    ##   `2ndFlrSF` = col_double(),
    ##   LowQualFinSF = col_double(),
    ##   GrLivArea = col_double(),
    ##   BsmtFullBath = col_double(),
    ##   BsmtHalfBath = col_double(),
    ##   FullBath = col_double()
    ##   # ... with 18 more columns
    ## )

    ## See spec(...) for full column specifications.

## preprocess

We’ll implement a number of preprocessing steps here. These are somewhat
generic because we didn’t do an EDA of our data. Again, the point of
this is to get a feel for a tidymodels workflow rather than to build a
really great model for this data. In these steps, we will:

1.  Convert all strings to factors
2.  Pool infrequent factors into an “other” category
3.  Remove near-zero variance predictors
4.  Impute missing values using k nearest neighbors
5.  Dummy out all factors
6.  Log transform our outcome (which is skewed)
7.  Mean center all numeric predictors (which will be all of them at
    this point)
8.  Normalize all numeric predictors

<!-- end list -->

``` r
preprocess_recipe <- train %>%
  select(-id) %>%
  recipe(sale_price ~ .) %>%
  step_string2factor(all_nominal()) %>% #this converts all of our strings to factors
  step_other(all_nominal(), threshold = .05) %>% #this will pool infrequent factors into an "other" category
  step_nzv(all_predictors()) %>% #this will remove zero or near-zero variance predictors
  step_knnimpute(all_predictors(), neighbors = 5) %>% #this will impute values for predictors using KNN
  step_dummy(all_nominal()) %>% #this will dummy out all factor variables
  step_log(all_outcomes()) %>% #log transforming the outcome because it's skewed
  step_center(all_numeric(), -all_outcomes()) %>% #this will mean-center all of our numeric data
  step_scale(all_numeric(), -all_outcomes()) %>% #this will normalize numeric data
  prep()

preprocess_recipe
```
