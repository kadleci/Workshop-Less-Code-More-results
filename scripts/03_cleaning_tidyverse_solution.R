# Solutions: cleaning with tidyverse (block 3)

library(tidyverse)
library(janitor)

# Exercises in the script --------------------------------------------------

# Exercise: unique values as a table with a pipeline
cats %>% distinct(species)
cats %>% count(species)    # also shows how many times each value occurs

# Question: why do we not need na_if("n/a")?
# as.numeric() turns every text that is not a number into NA,
# so "n/a" becomes NA on its own. R only shows the warning
# "NAs introduced by coercion".
as.numeric("n/a")

# Task: clean the raptor data, step by step -------------------------------

# 1. Load and look
raw_raptors <- read_csv("workshop_data/exercise_raptors_raw.csv")

glimpse(raw_raptors)

# 2. Czech column name and clean names
raptors <- raw_raptors %>%
  rename(species = Druh, temp_c = starts_with("Temp")) %>%
  clean_names() %>%
  rename(site_id = site)

names(raptors)

# 3. Unnecessary columns and duplicates
raptors <- raptors %>%
  select(-ring_number, -ringer, -weather, -notes) %>%
  distinct()

# 4. Text columns
raptors %>% count(species)   # "common buzzard" in lower case
raptors %>% count(sex)       # m, f, M, F

raptors <- raptors %>%
  mutate(
    sex = str_to_upper(sex),                                      # m -> M, f -> F
    species = str_replace(species, "common buzzard", "Common buzzard")
    # or: species = str_to_sentence(species)
  )

raptors %>% count(species)   # 6 species
raptors %>% count(sex)       # M, F

# 5. Weight
raptors$weight_g %>% unique()   # "n/a" makes the column text

raptors <- raptors %>%
  mutate(
    weight_g = as.numeric(weight_g),                # "n/a" -> NA
    weight_g = if_else(weight_g <= 0, NA, weight_g) # 0 and -999 -> NA
  )

summary(raptors$weight_g)

# 6. Check and save
glimpse(raptors)
summary(raptors)

write_csv(raptors, "workshop_data/raptors_clean.csv")

# Bonus: all steps in one pipeline -----------------------------------------

raptors <- read_csv("workshop_data/exercise_raptors_raw.csv") %>%
  rename(species = Druh, temp_c = starts_with("Temp")) %>%
  clean_names() %>%
  rename(site_id = site) %>%
  select(-ring_number, -ringer, -weather, -notes) %>%
  distinct() %>%
  mutate(
    sex = str_to_upper(sex),
    species = str_replace(species, "common buzzard", "Common buzzard"),
    weight_g = as.numeric(weight_g),
    weight_g = if_else(weight_g <= 0, NA, weight_g)
  )

write_csv(raptors, "workshop_data/raptors_clean.csv")
