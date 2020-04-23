library(tidymodels)
library(tidyverse)
library(parsnip)
library(DataExplorer)
library(scales)



len = function(x) {
  length(x)
}


data = tibble(winequality_red)
data %>% 
  names()

set.seed(123)
attach(data)
glimpse(data)
DataExplorer::create_report(data)

# from  HERE I CAN SEE THAT THERE AR E NOLY 6 
# OBS MISSING SO I CAN  COMPLETELY FORGET ABOUT THEM 

split = initial_split(data, props = 9/10)
wine_train = training(split)
wine_test  = testing(split)

wine_rec = 
  recipe(quality ~ ., data = wine_train) %>% 
  step_center(all_predictors()) %>%
  step_scale(all_predictors()) %>% 
  prep(training = wine_train, retain = T)

train_data = juice(wine_rec)
test_data  = bake(wine_rec, wine_test)

wine_model = linear_reg()
wine_model

lm_wine_model = 
  wine_model %>%
  set_engine("lm")
lm_wine_model

lm_fit =
  lm_wine_model %>%
  fit(quality ~ ., data = wine_train)


stan_wine_model =
  wine_model %>%
  set_engine("stan",  iter = 5000, prior_intercept = rstanarm::cauchy(0, 10), seed = 123)
stan_wine_model

stan_fit =
  stan_wine_model %>%
  fit(quality ~ ., data = wine_train)


predict(lm_fit, wine_test)
predict(stan_fit, wine_test)


predict(lm_fit, wine_test, type = "conf_int")
predict(stan_fit, wine_test, type = "conf_int")


