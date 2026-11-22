# Iteration: for loops, lapply() and map()
# We will use the clean big cat data from the cleaning script.

library(tidyverse) # purrr with map() is part of the tidyverse

cats <- read_csv("workshop_data/big_cats_clean.csv")

# Why do we need iteration? ----------------------------------------------

# Calculate the mean weight of each species without iteration:
mean(cats$weight_kg[cats$species == "Snow leopard"], na.rm = TRUE)
mean(cats$weight_kg[cats$species == "Clouded leopard"], na.rm = TRUE)
mean(cats$weight_kg[cats$species == "Eurasian lynx"], na.rm = TRUE)
mean(cats$weight_kg[cats$species == "Leopard"], na.rm = TRUE)
mean(cats$weight_kg[cats$species == "Pallas's cat"], na.rm = TRUE)

# Five almost identical lines.
# With 50 species or 50 files this would be long and easy to break.
# Rule of thumb: if you copy the same code more than twice, use iteration.

# Vector with all species names:
species_list <- unique(cats$species)
species_list

# for loop ---------------------------------------------------------------

# A for loop repeats the code inside {} for every value of a vector.
# for (variable in vector) {
#   code
# }

for (sp in species_list) {
  print(sp) # Print the name of each species
}

# To keep the results, we need to create an empty vector first.
mean_weight <- numeric(length(species_list)) # Empty vector for 5 numbers

for (i in seq_along(species_list)) {         # i = 1, 2, 3, 4, 5
  sp_data <- cats[cats$species == species_list[i], ] # Rows of one species
  mean_weight[i] <- mean(sp_data$weight_kg, na.rm = TRUE) # Save the result
}

names(mean_weight) <- species_list # Add species names to the results
mean_weight

# It works, but we need an empty vector, an index i and names at the end.

# lapply() and sapply() --------------------------------------------------

# lapply() runs a function on every element and returns a list.
# lapply(X, FUN, ...)
lapply(species_list, function(sp) {
  mean(cats$weight_kg[cats$species == sp], na.rm = TRUE)
})

# sapply() does the same, but simplifies the result to a vector if possible.
# sapply(X, FUN, ...)
sapply(species_list, function(sp) {
  mean(cats$weight_kg[cats$species == sp], na.rm = TRUE)
})

# Shorter code, no empty vector and no index.
# But sapply() decides on its own what type the result will be.

# map() ------------------------------------------------------------------

# map() works like lapply() and always returns a list.
# map(.x, .f, ...)
species_list %>%
  map(function(sp) mean(cats$weight_kg[cats$species == sp], na.rm = TRUE))

# \(x) is a short way to write function(x):
species_list %>%
  map(\(sp) mean(cats$weight_kg[cats$species == sp], na.rm = TRUE))

# map_*() functions say which type of result we expect:
# map()      list
# map_dbl()  numbers
# map_int()  whole numbers
# map_chr()  text
# map_lgl()  TRUE or FALSE
# If the result does not match the type, R gives an error.
species_list %>%
  set_names() %>% # Use species names as names of the results
  map_dbl(\(sp) mean(cats$weight_kg[cats$species == sp], na.rm = TRUE))

# For this simple task group_by() + summarise() is the easiest way:
cats %>%
  group_by(species) %>%
  summarise(mean_weight = mean(weight_kg, na.rm = TRUE))

# map() is useful when we repeat something more complex:
# reading files, fitting models or creating plots.

# Reading many files -----------------------------------------------------

# Field data often come in many files, for example one file per site.
# First we create such files from our data (normally you already have them).
dir.create("workshop_data/sites_split", showWarnings = FALSE)

cats %>%
  group_split(site_id) %>% # List with one table per site
  walk(\(df) write_csv(df, str_c("workshop_data/sites_split/",
                                 unique(df$site_id), ".csv")))

# walk() works like map(), but it is used for functions that save something
# and do not return any result.

# List all files in the folder:
files <- list.files("workshop_data/sites_split", full.names = TRUE)
files

# Read all files and put them together into one table.

# 1. With a for loop:
all_sites <- list()                    # Empty list for the tables

for (i in 1:length(files)) {           # i = 1, 2, 3, 4, 5, 6
  all_sites[[i]] <- read_csv(files[i]) # Save each table into the list
}

# seq_along(files) does the same as 1:length(files),
# but it also works safely when the vector is empty.
for (i in seq_along(files)) {
  all_sites[[i]] <- read_csv(files[i]) # Save each table into the list
}

all_sites <- bind_rows(all_sites)      # Stack them into one table

# 2. With lapply():
# We do not need to create an empty list first.
all_sites <- lapply(files, read_csv)   # List of 6 tables
all_sites <- bind_rows(all_sites)      # Stack them into one table

# Exercise: write the same with lapply() in one pipeline.

# 3. With map():
all_sites <- files %>%
  map(read_csv) %>% # List of 6 tables
  list_rbind()      # Stack them into one table

nrow(all_sites) # Same number of rows as cats

# All three give the same result.
# The for loop needs an empty list and an index,
# lapply() and map() do it in one step and map() fits into a pipeline.

# Older code uses map_df() for the same thing.
# It still works, but list_rbind() is recommended now.

# Saving plots -----------------------------------------------------------

# One plot for each species, saved as a separate file:
dir.create("plots", showWarnings = FALSE)

species_list %>%
  walk(\(sp) {
    p <- cats %>%
      filter(species == sp) %>%
      ggplot(aes(body_length_cm, weight_kg, color = sex)) +
      geom_point() +
      labs(title = sp, x = "Body length (cm)", y = "Weight (kg)") +
      theme_minimal()

    ggsave(str_c("plots/", sp, ".png"), p, width = 6, height = 4) # Save the plot
  })

list.files("plots")

# Exercise: save the same plots with a for loop or with lapply()
# into the folder plots. Is there any difference?

# Task: population trends -------------------------------------------------

# Run this code. It creates yearly counts of four African species
# from a camera trap survey.
set.seed(42)

counts <- expand_grid(
  species = c("Lion", "Cheetah", "Plains zebra", "Honey badger"),
  year = 2015:2024
) %>%
  mutate(
    trend = case_when(
      species == "Plains zebra" ~ 3,      # increasing
      species == "Cheetah" ~ -2,          # decreasing
      TRUE ~ 0                            # stable
    ),
    count = round(40 + trend * (year - 2015) + rnorm(n(), 0, 4))
  ) %>%
  select(-trend)

counts

# Use the way you like best: a for loop, lapply() or map().
#
# 1. Create a vector with the names of all species.
#
# 2. Fit a linear model count ~ year for each species.
#    Hint: lm(count ~ year, data = filter(counts, species == sp))
#
# 3. Get the slope of each model.
#    Hint: coef(model)[2] is the change in count per year.
#    Which species is increasing and which is decreasing?
#
# 4. Plot the counts of all species with a trend line.
#    Hint: geom_point(), geom_smooth(method = "lm"), facet_wrap()
#
# Bonus: save one plot per species into the folder plots_trends.
#
# Extra bonus: solve steps 2 and 3 in another way than you did first.

# Bonus: nest() + map() ----------------------------------------------------

# If there is time left: the same idea as above, but all in one table.

# In research we often repeat the same analysis for each individual,
# for example for every GPS collared animal.
# nest() creates one row per group, the column data holds its own table.
cats_nest <- cats %>%
  filter(!is.na(weight_kg), !is.na(body_length_cm)) %>%
  nest(data = -species) # Everything except species goes into data

cats_nest           # 5 rows, one for each species
view(cats_nest)     # Open the table in a new tab
cats_nest$data[[1]] # Table of the first species

# Table of one species with base R:
cats_nest$data[[which(cats_nest$species == "Leopard")]]

# Table of one species with tidyverse:
cats_nest %>%
  filter(species == "Leopard") %>%
  pull(data) %>% # List with one table
  pluck(1)       # Take the table out of the list

# map() inside mutate() runs a function on every small table
# and saves the result into a new column:
cats_nest <- cats_nest %>%
  mutate(
    n = map_int(data, nrow),                                           # Number of records
    model = map(data, \(d) lm(weight_kg ~ body_length_cm, data = d)),  # One model per species
    slope = map_dbl(model, \(m) coef(m)[2]),                           # Weight gain per 1 cm
    r2 = map_dbl(model, \(m) summary(m)$r.squared)                     # How well the model fits
  )

cats_nest %>% select(species, n, slope, r2)

# unnest() puts the small tables back into one big table:
cats_nest %>%
  select(species, data) %>%
  unnest(data)
