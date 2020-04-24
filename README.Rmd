---
title: "Recipe tutorial"
author: "Niccolò Salvini"
date: "24/4/2020"
output: html_document
---



### tutorial


![img1](img/logo.png)

this tutorial comes from the
[RStudio 2017](https://rstudio.com/resources/webinars/creating-and-preprocessing-a-design-matrix-with-recipes/)
conference where the author of the package
[Max Kuhn](https://resources.rstudio.com/authors/max-kuhn) explains the
functionalisties and the idea behind building the **recipe **. Those are all notes taken during the lecture


**warinng** something can have changes and it had. 

The idea is pretty simple once you have to cook a dish you have to know
the recipe. Once yoi know the recipe which is basicallu a sequence of
simple steps you can then perform the dish and serve it. If at some
point you understand that the dish is missing something, say some spicy,
you should not *undish* the dinner but simply go get the grocery at the
store and add the extraflavour in the right spot, without say messing
the impiattamento. This is mainly good for at **least 4 reasons**:

1. itfollows good statistical practice 
1. it keeps all the stuff well ordered
1. it gives a solution toghether with the *parnsip* to gather all the different models into one common framework 
1. once you have done it forthe first time it is just a matter of copy and paste

```{r, warning=FALSE, message=FALSE}

library(recipes)
library(tidyverse) 
library(caret) 
library(dimRed)

```

``` {r}

data(Sacramento)

rec  = recipe(price ~ type + sqft, data = Sacramento)
rec = rec %>%  
  step_log(price) %>% 
  step_dummy(type)

rec
```

one you have initialized the recipe you can start add steps to the
recipe: so if you want to take the original recipe and add a step said
to be *step_log* and you simply put the variabile inside the
parentheses and that modifies the recipe including the step done (this
as it is said will add the logarithm to the variable price) then say
that you want to dummyfy the varible type. You pipe operate all the
previous recipe and you add simply one other step. and this decribes the
preprocess operations you want to have, but again all it is doing is to
specify all the operation that we want to perform, they are no actually
do anything for the moment.

``` {r}

rec_trained = prep(rec, training = Sacramento, retain = T)

```

then in the chunk above you are **preparing** the recipe as it is said,
this preparing can be see as the training fitting the preprocess step
but actually not computationallu doing it. It prints the steps, it helps
you to keep track of what you are doing. the *retain = T* take the
dataset tahti give it and when you estimate keep that modified verison
on the training so that you do not have to do it many times.

``` {r}
design_mat = bake(rec_trained, new_data = Sacramento)
```

now going on with the analogy you cook the recipe, so we take the object
that we created and then apply this recipe to the dataset that I have.
It like an apply method. the reason why you can specify the dataset is
that the [4^{th}] I said before, once you specify the recipe you can
cook pass throught the steps any ingredients that you want. **So this is
the full idea behind** the rest are all the features of the package, so
all the steps that you can add to your dataset preprocess and so on.

this is all about dplyr sintax. For the moment we still didnt encode any
variables, didnt do any PCA (any sort of selection features) nor
discretized predictors with dynamic bins. What the dplyr syntax actually
permits us to do is to apply the step to a set of columns, instead for a
single one.

```{r, echo=FALSE, error=FALSE, eval=FALSE}

step_spatialsign(matches(“PC[1-9]”), all_numeric(),-all_outcomes())

```

One other interesting feature is that you can decide before actually
perfoming operations how many pca’s you want, you might want to do
operation that actually are not still performed. really really rich set
of steps.

One cool thing about the recipe is taht is cumulative so that you can
split the preprocess into parts so that you can be very precise. see
below:

``` {r}

standardized = rec_trained %>% 
  step_center(all_numeric()) %>% 
  step_scale(all_numeric()) %>% 
  step_pca(all_numeric())

standardized = prep(standardized)
standardized
```

you can just keep add steps to it, so you added to the first recipe that
logged the price and creates the dummy variable, you do not do to redo
anything. it does not make sense for this varibales but it is just to
give a test of what you can do. If you didnt *retain = T* then when you
are refitting in the standardized you are going to loose work, so make
sure you do not forget it. those below are some of the steps you can
perform, this presentation come from **2017** so the mantainers will for
sure have updated it with the latest technologies

![img1](img/img1.PNG)

econding: dummy variables, discretization, date feature: you can model
holidays (purrr it before) imputation: all the main imputation

Once you have all set up you can call the fucntion that wraps all
toghether like in the python framework:

``` {r}
lin_reg.recipe = function(rec,data) {
  trained = prep(rec, training = data)
  lm.fit(x= bake(trained, new_data = data, all_predictors()),
         y =bake(trained, new_data = data, all_outcomes()))
  
}

```

## An Example 

[Kuhn and Johnson](http://appliedpredictivemodeling.com) (2013) analyze a data set where thousands of cells are determined to be well-segmented (WS) or poorly segmented (PS) based on 58 image features. We would like to make predictions of the segmentation quality based on these features. 

```{r image_load}
library(dplyr)
library(caret)
data("segmentationData")
seg_train <- segmentationData %>% 
  filter(Case == "Train") %>% 
  select(-Case, -Cell)
seg_test  <- segmentationData %>% 
  filter(Case == "Test")  %>% 
  select(-Case, -Cell)
```



## A Simple Recipe

```{r image_rec}
rec <- recipe(Class  ~ ., data = seg_train)
basic <- rec %>%
  # Correct some predictors for skewness
  step_YeoJohnson(all_predictors()) %>%
  # Standardize the values
  step_center(all_predictors()) %>%
  step_scale(all_predictors())
# Estimate the transformation and standardization parameters 
basic <- prep(basic, training = seg_train, verbose = FALSE, retain = TRUE)  
```



## Principal Component Analysis

```{r image_pca}
pca <- basic %>% step_pca(all_predictors(), threshold = .9)
summary(pca)
```


## Principal Component Analysis

```{r image_pca_train}
pca <- prep(pca)
summary(pca)
pca <- bake(pca, new_data = seg_test, everything())
```


## Principal Component Analysis

```{r image_pca_plot, fig.keep="none"}
pca[1:4, 1:8]
ggplot(pca, aes(x = PC01, y = PC02, color = Class)) + geom_point(alpha = .4)
```


## Principal Component Analysis

```{r image_pca_fig, echo = FALSE, fig.width = 5.5, fig.height = 5.6}
rngs <- extendrange(c(pca$PC01, pca$PC02))
ggplot(pca, aes(x = PC01, y = PC02, color = Class)) + 
  geom_point(alpha = .4) + 
  xlim(rngs) + ylim(rngs) + 
  theme(legend.position = "top")
```



## Kernel Principal Component Analysis

```{r kpca}
kern_pca <- basic %>% 
  step_kpca(all_predictors(), num = 2, 
            options = list(kernel = "rbfdot", 
                           kpar = list(sigma = 0.05)))
kern_pca <- prep(kern_pca)
kern_pca <- bake(kern_pca, new_data = seg_test, everything())
```


## Kernel Principal Component Analysis

```{r image_kpca_fig, echo = FALSE, fig.width = 5.5, fig.height = 5.6}
rngs <- extendrange(c(kern_pca$kPC1, kern_pca$kPC2))
ggplot(kern_pca, aes(x = kPC1, y = kPC2, color = Class)) + 
  geom_point(alpha = .4) + 
  xlim(rngs) + ylim(rngs) + 
  theme(legend.position = "top")
```


## Distance to Each Class Centroid

```{r dists, message = FALSE}
dist_to_classes <- basic %>% 
  step_classdist(all_predictors(), class = "Class") %>%
  # Take log of the new distance features
  step_log(starts_with("classdist"))
dist_to_classes <- prep(dist_to_classes, verbose = FALSE)
# All variables are retained plus an additional one for each class
dist_to_classes <- bake(dist_to_classes, new_data = seg_test, matches("[Cc]lass"))
dist_to_classes
```



## Distance to Each Class

```{r image_dists_fig, echo = FALSE, fig.width = 5.5, fig.height = 5.6}
rngs <- extendrange(c(dist_to_classes$classdist_PS, dist_to_classes$classdist_WS))
ggplot(dist_to_classes, aes(x = classdist_PS, y = classdist_WS, color = Class)) + 
  geom_point(alpha = .4) + 
  xlim(rngs) + ylim(rngs) + 
  theme(legend.position = "top") + 
  xlab("Distance to PS Centroid (log scale)") + 
  ylab("Distance to WS Centroid (log scale)")
```

