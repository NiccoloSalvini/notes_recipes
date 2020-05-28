AllenatiPCA
================
Niccolò Salvini
28, maggio 2020

## la ricetta da cucinare

  - la ricetta preve la variabile da spiegare cioè points, che vuole
    essere spiegata da tutti gli altri predittori
  - `update_role()` permette di separare temporaneamente dal dataset due
    predittori che non sarebbero utili all’interno della PCA, dato il
    fatto che sono due ID predictors. I predittori sono messi in un
    metacolonna ID affichè non finiscano nella ricetta sotto forma di
    predittori

> In recipes, variables can have different roles (e.g. “predictor” or
> “outcome”). Beyond those set by the package, roles are largely user
> specified and can be pretty much anything.

  - viene passato dentro un logaritmo la variabile di risposta.
  - vengono normalizzati tutti i predittori

<!-- end list -->

``` r
library(tidymodels)

ranking_rec <- recipe(points ~ ., data = ranking_df) %>%
  update_role(title, artist, new_role = "id") %>%
  step_log(points) %>%
  step_normalize(all_predictors()) %>%
  step_pca(all_predictors())

ranking_prep <- prep(ranking_rec)

ranking_prep
```

## qui vedi cosa spinge di più

  - `tidy()` permette di prendere come input la terza ricetta in ordine
    logico chronologico, che corrisonde alla PCA.
  - la fa passare dentro `mutate()` riordinando la colonna component
  - poi decide di lanciare un `ggplot` dove sulle x mette i valore della
    PCA, sulle y mette i predittori e li rimepie con colori diversi per
    ogni predittore.
  - decide che il bar chart sia la rappresentazione giusta.
  - succesivamente `facet_wrap()` per differenzialo per ogni componente.

<!-- end list -->

``` r
tidied_pca = tidy(ranking_prep, 3)

tidied_pca %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(value, terms, fill = terms)) +
  geom_col(show.legend = FALSE) +
  facet_wrap(~component) +
  labs(y = NULL)
```

<p align="center">

<img src="img/pca1.png" width="724" />

</p>

da questa vede quale predittore impatta sulla varianza spiegata per ogni
componente cosicchè dopo a coppia li confronta e nella rappresentazione
riesce a distinguere brano da brano (qui il dataset analizzava la
canzone hip hop più riprodotta)

## qui zooma dentro le singole componenti

decide di riarrangiare le componenti di modo che siano in ordine
decrescente, sicuramente più facile da digerire.

  - prende il solito pezzetto finale di ricetta (non fittato) e lo
    filtra per le prime quattro componenti
  - lo raggruppa per componenti e prende i primi 6 predittori, che sono
    quelli, tra gli altri, spiegano di più la varianza.
  - li disaggrega con `ungroup()`
  - qui con passa dentro `mutate()` una funziona che va a modificare la
    variabile terms (dove sono tutte le componenti). La funzione è
    `reorder_within()`. Necessita di fare il valore assoluto perchè le
    componenti possono avere valori negativi. Le passa dentro `abs()`
    per evitare che siano negative. Una componente può essere anche
    fortemente negativa, ma non vuol dire che non spieghi la varianza.
  - successivamente ci lega un `ggplot` a colonna che è un barplot. lo
    facetta per componente e libera le Y cosicchè non dipendano tutte
    dalla grandezza della prima componente. La prima componente
    principale è anno che spiega tanta varianza.
  - decide di colorarle di due colori il rosso chiaro e il verde, questo
    perchè alcune componenti spiegano bene la varianza ma in negativo
    (sono correlate negativamente), nella prima componente: *year* and
    *danceability* (correlazione opposta, una rossa e una blu) \_\_
    nella seconda componente *energy* and *loudness* (correlate
    positivamente, tutte e due verdi)
  - aesthetics

<!-- end list -->

``` r
library(tidytext)

tidied_pca %>%
  filter(component %in% c("PC1", "PC2", "PC3", "PC4")) %>%
  group_by(component) %>%
  top_n(6, abs(value)) %>%
  ungroup() %>%
  mutate(terms = reorder_within(terms, abs(value), component)) %>%
  ggplot(aes(abs(value), terms, fill = value > 0)) +
  geom_col() +
  facet_wrap(~component, scales = "free_y") +
  scale_y_reordered() +
  labs(
    x = "Absolute value of contribution",
    y = NULL, fill = "Positive?"
  )
```

<p align="center">

<img src="img/pca2.png" width="1043" />

</p>

1.  la prima componenente viene spiegata bene da due predittori: YEARS
    and DANCEABILITY
2.  la seconda componente viene spiegata bene da due predittori: ENERGY
    and LOUDNESS etc etc.

> So PC1 is mostly about age and danceability, PC2 is mostly energy and
> loudness, PC3 is mostly speechiness, and PC4 is about the musical
> characteristics (actual key and major vs. minor key).

## sorta di biplot non evidenziato

  - strizza la ricetta (qui chiede computational power)
  - poi plotta le prime due componenti e decide di mettere la label col
    titolo, cosicchè per ogni punto ci sia il nome della canzone,
  - si accorge che ce ne sono tanto e le vela con un alpha basso
  - `geom_text()` lo usa per evitare overlapping di parole. Poi matcha
    il family font perchè è malata di mente.

<!-- end list -->

``` r
juice(ranking_prep) %>%
  ggplot(aes(PC1, PC2, label = title)) +
  geom_point(alpha = 0.2) +
  geom_text(check_overlap = TRUE, family = "IBMPlexSans")
```

<p align="center">

<img src="img/pca3.png" width="1019" />

</p>

qui capisco che decide di plottare le prime due componenti una contro
l’altra per vedere nelle rispettive due dimensioni, a seconda della
direzione della componente se negativa o positiva dove si colloca la
canzone. In altre parole: se ti sposti sul’asse delle *X* a destra stai
andando nella prima componente a valori grandi quindi stai guardando le
canzoni molto nuove (year alto) e poco ballabili (perchè il predittore
danceability ha i loadings nella direzione opposta). Allo stesso modo
posso fare screening sull’asse delle y, nella parte alta del grafico mi
aspetto di vedere vanzoni energetiche e chiassose, in basso il
contrario.

## quanta varinaza catturo?

vale la pena chiedersi allora di quante componenti ho bisogno quindi
plotto la varianza spiegata ed arrangiata per tutte le componenti. -
prendo la deviazione std delle componenti e la metto in una variabile
*sdev* - calcolo la proporzione applicando ufunc su tutto il vettore -
la metto in un `tibble` perchè a quanto pare esce in una classe diversa
- quindi plotto a colonna e sistemo il formato - aesthetics

``` r
sdev = ranking_prep$steps[[3]]$res$sdev

percent_variation = sdev^2 / sum(sdev^2)

tibble(
  component = unique(tidied_pca$component),
  percent_var = percent_variation ## use cumsum() to find cumulative, if you prefer
) %>%
  mutate(component = fct_inorder(component)) %>%
  ggplot(aes(component, percent_var)) +
  geom_col() +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(x = NULL, y = "Percent variance explained by each PCA component")
```

<p align="center">

<img src="img/pca4.png" width="1186" />

</p>
