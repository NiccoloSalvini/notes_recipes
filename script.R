lmFit = train(Y ~ X1 + X2, data = training, 
               method = "lm", 
               trControl = fitControl)

spec_lin_reg = linear_reg() %>%   # a linear model specification
  set_engine( "lm")  # set the model to use lm
# fit the model
lm_fit = fit(spec_lin_reg, Y ~ X1 + X2, data = my_data)


spec_stan = 
  spec_lin_reg %>%
  set_engine("stan", chains = 4, iter = 1000) # set engine specific arguments

fit_stan = fit(spec_stan, Y ~ X1 + X2, data = my_data)


flights_rec = recipe(arr_delay ~ ., data = train_data) %>%
  update_role(flight, time_hour, new_role = "ID") %>% 
  step_date(date, features = c("dow", "month")) %>% 
  step_rm(date) %>% 
  step_dummy(all_nominal(), -all_outcomes())


lr_mod = logistic_reg() %>%
  set_engine("glm")


flights_wflow = workflow() %>% 
  add_model(lr_mod) %>%
  add_recipe(flights_rec)



flights_fit = fit(flights_wflow, data = train_data)

set.seed(123)
folds = vfold_cv(train_data, v = 10)
flights_fit_rs = fit_resamples(flights_wflow, folds)

collect_metrics(flights_fit_rs)





