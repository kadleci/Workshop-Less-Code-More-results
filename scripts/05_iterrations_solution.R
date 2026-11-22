# Solutions: iteration with for loops, lapply() and map()
# Run the iteration script first, these solutions use its objects
# (cats, species_list, files, counts).

library(tidyverse)

# Exercise: write the same with lapply() in one pipeline -----------------

all_sites <- files %>%
  lapply(read_csv) %>% # List of 6 tables
  bind_rows()          # Stack them into one table

# Exercise: save the plots with a for loop or with lapply() --------------

# With a for loop:
for (sp in species_list) {
  p <- cats %>%
    filter(species == sp) %>%
    ggplot(aes(body_length_cm, weight_kg, color = sex)) +
    geom_point() +
    labs(title = sp, x = "Body length (cm)", y = "Weight (kg)") +
    theme_minimal()

  ggsave(str_c("plots/", sp, ".png"), p, width = 6, height = 4)
}

# With lapply():
lapply(species_list, function(sp) {
  p <- cats %>%
    filter(species == sp) %>%
    ggplot(aes(body_length_cm, weight_kg, color = sex)) +
    geom_point() +
    labs(title = sp, x = "Body length (cm)", y = "Weight (kg)") +
    theme_minimal()

  ggsave(str_c("plots/", sp, ".png"), p, width = 6, height = 4)
})

# Is there any difference?
# The plots are the same. But lapply() returns a list of the file names
# that ggsave() created and prints it in the console.
# The for loop and walk() print nothing, because we only want to save files.

# Task: population trends -------------------------------------------------

# 1. Vector with species names
trend_species <- unique(counts$species)

# 2. One linear model per species

# With a for loop:
models <- list()                       # Empty list for the models

for (sp in trend_species) {
  models[[sp]] <- lm(count ~ year, data = filter(counts, species == sp))
}

# With lapply():
models <- lapply(trend_species, function(sp) {
  lm(count ~ year, data = filter(counts, species == sp))
})
names(models) <- trend_species         # lapply() does not keep the names

# With map():
models <- trend_species %>%
  set_names() %>%                      # Use species names as names of the results
  map(\(sp) lm(count ~ year, data = filter(counts, species == sp)))

models

# 3. Slope of each model = change in count per year

# With a for loop:
slopes <- numeric(length(models))      # Empty vector for the slopes

for (i in seq_along(models)) {
  slopes[i] <- coef(models[[i]])[2]
}

names(slopes) <- names(models)
slopes

# With sapply() (returns a vector, lapply() would return a list):
sapply(models, function(m) coef(m)[2])

# With map_dbl():
models %>% map_dbl(\(m) coef(m)[2])

# Plains zebra is increasing, Cheetah is decreasing,
# Lion and Honey badger are stable (slope close to 0).

# 4. Trends of all species
ggplot(counts, aes(year, count)) +
  geom_point() +
  geom_smooth(method = "lm") +
  facet_wrap(~ species) +
  labs(x = "Year", y = "Number of animals") +
  theme_minimal()

# Bonus: one plot per species
dir.create("plots_trends", showWarnings = FALSE)

# With a for loop:
for (sp in trend_species) {
  p <- counts %>%
    filter(species == sp) %>%
    ggplot(aes(year, count)) +
    geom_point() +
    geom_smooth(method = "lm") +
    labs(title = sp, x = "Year", y = "Number of animals") +
    theme_minimal()

  ggsave(str_c("plots_trends/", sp, ".png"), p, width = 6, height = 4)
}

# With walk() (lapply() works too, but prints a list of file names):
trend_species %>%
  walk(\(sp) {
    p <- counts %>%
      filter(species == sp) %>%
      ggplot(aes(year, count)) +
      geom_point() +
      geom_smooth(method = "lm") +
      labs(title = sp, x = "Year", y = "Number of animals") +
      theme_minimal()

    ggsave(str_c("plots_trends/", sp, ".png"), p, width = 6, height = 4)
  })

list.files("plots_trends")
