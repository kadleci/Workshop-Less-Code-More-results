# Cleaning the big cat capture data with tidyverse (block 3)
# Input:  workshop_data/big_cats_raw.csv, workshop_data/sites.csv
# Output: workshop_data/big_cats_clean.csv (used later for ggplot)

library(tidyverse)   # dplyr, tidyr, readr, stringr, ggplot2
library(lubridate)   # working with dates and times
library(janitor)     # clean_names()

## 1. Load the data ----

# read_csv() removes spaces around text values automatically (trim_ws = TRUE)
raw <- read_csv("workshop_data/big_cats_raw.csv")
sites <- read_csv("workshop_data/sites.csv")

# Always look at the data first: column names, types and first values
glimpse(raw)
head(raw)

## 2. Column names and unnecessary columns ----

cats <- raw %>%
  # The Czech name and the degree symbol are renamed by hand,
  # clean_names() would not give us the English names we want
  rename(sex = `Pohlaví`, temp_c = starts_with("Temp")) %>%
  # Lower case, no spaces or brackets: "Weight (kg)" becomes weight_kg
  clean_names() %>%
  rename(site_id = site) %>%
  # Remove the columns we do not need for the analysis
  # (or keep only the ones we need: select(record_id, site_id, timestamp, ...))
  select(-trap_id, -observer, -notes, -lab_code) %>%
  # Remove duplicated rows (identical in all columns)
  distinct()

# Look at the data again. What has changed and what is still wrong?
glimpse(cats)
head(cats)

## 3. Text columns ----

# Find the problems first: which values occur in the column?
unique(cats$species)
# Exercise: how can you get the same with a pipeline?

cats <- cats %>%
  mutate(
    # "s03" -> "S03"
    site_id = site_id %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_upper(),                     # all letters in upper case

    # First fix spaces and upper/lower case, then the typos.
    # In the opposite order "pallas cat" in lower case would stay unfixed.
    species = species %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_sentence() %>%               # capital letter only at the start
      str_replace("linx", "lynx") %>%     # replace "linx" with "lynx"
      str_replace("^Pallas cat$", "Pallas's cat"),   # ^ start, $ end of text

    # "male", "m", " M" -> "M"
    sex = sex %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_upper() %>%                  # all letters in upper case
      str_sub(1, 1),                      # keep only the first letter

    # "Adult", "sub adult" -> "adult", "subadult"
    age_class = age_class %>%
      str_trim() %>%                      # remove spaces before and after
      str_to_lower() %>%                  # all letters in lower case
      str_remove_all(" ")                 # remove all spaces inside the text
  )

# Check that only the expected categories are left
cats %>% count(species)     # 5 species
cats %>% count(sex)         # M, F
cats %>% count(age_class)   # adult, subadult
cats %>% count(site_id)     # S01 to S06

## 4. Numeric columns ----

# Find the problems first: weight_kg is <chr>, so something in it is not a number
glimpse(cats)
cats$weight_kg %>% unique()

cats <- cats %>%
  mutate(
    # Weight was loaded as text because of the decimal commas.
    # Replace commas, turn "n/a" into a real NA and convert to a number.
    weight_kg = weight_kg %>%
      str_replace(",", ".") %>%
      na_if("n/a") %>%
      as.numeric(),

    # 0 and -999 are codes for missing values, not real weights
    # if_else(condition, value if TRUE, value if FALSE)
    weight_kg = if_else(weight_kg <= 0, NA_real_, weight_kg),
    body_length_cm = if_else(body_length_cm <= 0, NA_real_, body_length_cm),

    # Some lengths were entered in wrong units:
    # 1.1 is in metres, 1100 is in millimetres
    # case_when() checks the conditions from top to bottom, the first TRUE wins
    body_length_cm = case_when(
      body_length_cm < 10 ~ body_length_cm * 100,    # m -> cm
      body_length_cm > 500 ~ body_length_cm / 10,    # mm -> cm
      TRUE ~ body_length_cm                          # everything else stays
    )
  )

# min and max quickly show values that make no sense
summary(cats$weight_kg)
summary(cats$body_length_cm)

## 5. Outliers ----

# Find the problems first: a boxplot per species shows the extreme values
ggplot(cats, aes(species, weight_kg)) +
  geom_boxplot()

# How do we decide what is an outlier? We use the IQR rule (Tukey's rule),
# the same rule that a boxplot uses to draw the separate points.
#
# Q1 (1st quartile)  = 25 % of values are smaller than this
# Q3 (3rd quartile)  = 75 % of values are smaller than this
# IQR = Q3 - Q1      = the range of the middle half of the data (the box)
#
# A value is an outlier when it is far from the box:
#   lower limit = Q1 - 3 * IQR
#   upper limit = Q3 + 3 * IQR
# Boxplots use 1.5 * IQR. We use 3 * IQR to remove only extreme values
# (typing errors), not animals that are just a bit bigger or smaller.
#
# Why per species? A weight of 3 kg is normal for Pallas's cat,
# but impossible for a leopard. With limits calculated for all cats
# together, the small and large species would hide each other's errors.

# Step 1: calculate the limits for each species and look at the outliers
cats <- cats %>%
  group_by(species) %>%                               # calculations per species
  mutate(
    q1 = quantile(weight_kg, 0.25, na.rm = TRUE),     # na.rm = TRUE ignores NA
    q3 = quantile(weight_kg, 0.75, na.rm = TRUE),
    iqr = q3 - q1,
    lower = q1 - 3 * iqr,
    upper = q3 + 3 * iqr,
    outlier = weight_kg < lower | weight_kg > upper   # | means "or"
  ) %>%
  ungroup()                                           # remove the grouping

# group_by() + mutate() keeps all rows and adds the limits to each of them
# (group_by() + summarise() would give one row per species instead)
cats %>%
  filter(outlier) %>%
  select(record_id, species, weight_kg, lower, upper)   # 4500, 450 and 0.4 kg

# Step 2: replace the outliers with NA and remove the helper columns
# We use NA instead of deleting the row, so the other measurements are kept
cats <- cats %>%
  mutate(weight_kg = if_else(outlier, NA_real_, weight_kg, missing = weight_kg)) %>%
  select(-q1, -q3, -iqr, -lower, -upper, -outlier)

# Check: the boxplot again, the extreme points should be gone
ggplot(cats, aes(species, weight_kg)) +
  geom_boxplot()

## 6. Dates and times ----

# Find the problems first: timestamp is <chr> and has two different formats
cats$timestamp %>% unique() %>% head(20)

cats <- cats %>%
  mutate(
    # Timestamps are stored in two formats:
    # "2024-01-15 22:30:00" and "15.01.2024 22:30"
    # parse_date_time() tries both orders and reads both of them
    timestamp = parse_date_time(timestamp, orders = c("Ymd HMS", "dmY HM")),
    date = as_date(timestamp),     # only the date, without time
    year = year(timestamp),
    month = month(timestamp)
  )

# Check: how many records have no timestamp (missing already in the raw data)
cats %>% filter(is.na(timestamp)) %>% nrow()

## 7. Add habitat from the sites table ----

# left_join() keeps all records and adds habitat by matching site_id
cats <- cats %>%
  left_join(sites %>% select(site_id, habitat), by = "site_id") %>%
  relocate(habitat, .after = site_id) %>%   # move habitat next to site_id
  arrange(timestamp)                        # sort by time

## 8. Final check ----

glimpse(cats)

# Number of NA values in each column
cats %>% summarise(across(everything(), ~ sum(is.na(.x))))

# A quick plot is the fastest way to spot anything that is still wrong
ggplot(cats, aes(body_length_cm, weight_kg, color = species)) +
  geom_point()

## 9. Wide to long format ----

# Monthly counts are in separate columns (Jan, Feb, ...).
# For ggplot we need one column with the month and one with the count.
captures_long <- read_csv("workshop_data/captures_wide.csv") %>%
  pivot_longer(Jan:Dec, names_to = "month", values_to = "n")

## 10. Save the clean data ----

write_csv(cats, "workshop_data/big_cats_clean.csv")
